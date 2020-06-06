//
//  DidChoosePlaygrounds.swift
//  PlaygroundPackageManager
//
//  Created by Peter Schorn on 4/25/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation
import SwiftUI
import AppKit
import Utilities

let finder = FileManager.default



func didChoosePlaygrounds(
    playgrounds: [URL],
    repos: Set<SavedRepository>,
    alertCallback: @escaping (_ title: String, _ msg: String) -> Void,
    needRepoName: @escaping (
        _ repoURL: String,
        _ cloningMsg: UUID,
        _ gotName: @escaping (_ name: String) -> Void
    ) -> Void,
    showFilePicker: @escaping (_ show: @escaping (_ competion: @escaping () -> Void) -> Void) -> Void,
    completion: @escaping () -> Void
) {
    
    
    var seenRepos: Set<String> = []
 
    // print("didChoosePlaygrounds: number of repos:", repos.count)
    for repo in repos {
        
        if !seenRepos.insert(repo.url).inserted {
            print("tried to download duplicate url")
            continue
        }
        
        // print("pushing cloningMsg")
        let cloningMsg = pushStatusMessage("cloning \(repo.url)", isLoading: true)
        
        // print("cloning \(repo.url)")
        do {
            try withTempDirectory(deleteOptions: .useHandler) { tempDir, deleteTempDir in
                
                globalEnv.tempDirectories.append(tempDir)
                
                print("tempDir:", tempDir.path)
                
                let task = runShellScriptAsync(args: ["git", "clone", repo.url, tempDir.path]) {
                    process, stdout, stderror in
                    
                    print("git clone stdout: ", stdout ?? "nil")
                    // print("stdout: [\(stdout ?? "nil")]")
                    // print("stderror: [\(stderror ?? "nil")]")
                    // print("exit code: ", process.terminationStatus)
                    
                    print("termination status for \(repo.url):", process.terminationStatus)
                    
                    if process.terminationReason == .uncaughtSignal {
                        deleteTempDir?()
                        return
                    }
                    
                    if process.terminationStatus != 0 {
                        alertCallback(
                            "git clone finished with a non-zero exit code",
                            stderror ?? "no error information was provided by git"
                        )
                        print("non zero removing status message for url:")
                        print(repo.url)
                        removeStatusMsg(cloningMsg)
                        deleteTempDir?()
                        return
                    }
                    
                    updateStatusMessage(id: cloningMsg, isLoading: false)
                    
                    let package = tempDir.appendingPathComponent("Package.swift")
                    
                    // #warning("DEBUG: Can't find repository name")
                    let packageName: String
                    
                    let actualRepo = globalEnv.saved_repos.first { $0.id == repo.id }
                    if let name = actualRepo?.name {
                        print("found package name in struct:", name)
                        packageName = name
                    }
                    // MARK: Try to get the package name from Package.swift
                    else if let packageContents = try? String(contentsOf: package),
                            let name = try! packageContents.regexMatch(#"name: "(.*?)","#)?.groups[0]?.match {
                    
                        packageName = name
                        print("found package name in Package.swift:", packageName)
                    
                        changeRepo(.name(packageName), id: repo.id)
                    
                    }
                    // MARK: - Ask User for Repository Name -
                    else {
                        
                            print(
                                """
                                --------------------
                                calling needRepoName for
                                \(repo.url)
                                --------------------
                                """
                            )
                            
                            needRepoName(repo.url, cloningMsg) { receivedName in
                                
                                print(
                                    """
                                    -----------------------------------
                                    inside needRepoName: received name:
                                    \(receivedName)
                                    -----------------------------------
                                    """
                                )
                                
                                changeRepo(.name(receivedName), id: repo.id)
                                
                                moveRepoToPlaygrounds(
                                    repoPath: tempDir,
                                    repo: repo,
                                    packageName: receivedName,
                                    playgrounds: playgrounds,
                                    alertCallback: alertCallback,
                                    cloningStatusMsg: cloningMsg,
                                    deleteTempDir: deleteTempDir,
                                    showFilePicker: showFilePicker,
                                    completion: completion
                                )
                            }
                        
                        return
                    }
                    
                    moveRepoToPlaygrounds(
                        repoPath: tempDir,
                        repo: repo,
                        packageName: packageName,
                        playgrounds: playgrounds,
                        alertCallback: alertCallback,
                        cloningStatusMsg: cloningMsg,
                        deleteTempDir: deleteTempDir,
                        showFilePicker: showFilePicker,
                        completion: completion
                    )
                
                } // end runShellScriptAsync
                
                globalEnv.cancelTaskCallbacks.append {
                    task.terminate()
                    removeStatusMsg(cloningMsg)
                }
                
            } // end withtempDirrectory
        
        } catch {  // error creating temporary directory
            alertCallback(
                "Couldn't create temporary directory to clone the repository into",
                "\(error)"
            )
        }
    } // end for repo in repos

}
        


func moveRepoToPlaygrounds(
    repoPath: URL,
    repo: SavedRepository,
    packageName: String,
    playgrounds: [URL],
    alertCallback: @escaping (_ title: String, _ msg: String) -> Void,
    cloningStatusMsg: UUID,
    deleteTempDir: (() -> Void)?,
    showFilePicker: @escaping (_ show: @escaping (_ competion: @escaping () -> Void) -> Void) -> Void,
    completion: @escaping () -> Void
) {
    
    func gotSourcesDirectory(sourcesDirectory: URL) {
        
        let sourcesDirOriginal = try! sourcesDirectory.cannonicalPath()!
        let repoPathOriginal = try! repoPath.cannonicalPath()!
        
        // print("\n\ngotSourcesDirectory:")
        // print(sourcesDirOriginal)
        // print("repoPath:")
        // print(repoPathOriginal)
        
        let repoPathCount = repoPathOriginal.pathComponents.count
        var relativeSourceDir =
                sourcesDirOriginal.pathComponents[repoPathCount...].joined(
            separator: "/"
        )
        if !relativeSourceDir.hasSuffix("/") {
            relativeSourceDir += "/"
        }
        
        // print("relative sources directory: [\(relativeSourceDir)]")
        
        changeRepo(.sourcesDir(relativeSourceDir), id: repo.id)
        
        
        print("\n\n gotSourcesDirectory: number of playgrounds: \(playgrounds.count)")
        for playground in playgrounds {
            
            let addingPackageMsg = pushStatusMessage(
                "Adding package '\(packageName)' to playground '\(playground.lastPathName)'",
                isLoading: true
            )
            
            let playgroundSources = playground.appendingPathComponent(
                "Sources", isDirectory: true
            )
            
            do {
                if !isExistingDirectory(playgroundSources) {
                        try makeFolder(playgroundSources)
                }
                let newPackagePath = playgroundSources.appendingPathComponent(
                    packageName, isDirectory: true
                )
                
                // let replacedPrevious: Bool
                
                if finder.fileExists(atPath: newPackagePath.path) {
 
                    try finder.removeItem(at: newPackagePath)
                }
                else {
                    // replacedPrevious = false
                }
                
                // print("trying to copy item")
                try finder.copyItem(at: sourcesDirOriginal, to: newPackagePath)

                
                updateStatusMessage(id: addingPackageMsg, isLoading: false)
                
            
            } catch {
                removeStatusMsg(addingPackageMsg)
                alertCallback(error.localizedDescription, "\(error)")
            }
            
        }
        
        // print("---\nFinished adding repos to playgrounds\n---")
        deleteTempDir?()
        completion()
    }

    var sourceDirNames = ["Sources/", "Source/"]
    if let savedSourceDir = repo.sourcesDir {
        sourceDirNames.insert(savedSourceDir, at: 0)
        print("found saved sources dir in struct:", savedSourceDir)
    }
    
    for (n, source) in sourceDirNames.enumerated() {
        let sourcesDir = repoPath.appendingPathComponent(source, isDirectory: true)
        if isExistingDirectory(sourcesDir) {
            gotSourcesDirectory(sourcesDirectory: sourcesDir)
            break
        }
        if n == sourceDirNames.count - 1 {
            
            DispatchQueue.main.async {
                
                print("couldn't find sources directory; asking user")
                let filePicker = NSOpenPanel()
                filePicker.canChooseFiles = false
                filePicker.canChooseDirectories = true
                filePicker.allowsMultipleSelection = false
                filePicker.directoryURL = repoPath
                filePicker.prompt = "Choose"
                filePicker.message =
                """
                Please select the sources folder for the package '\(packageName)'.
                Adding the entire package prevents the playground from compiling.
                """
                
                showFilePicker() { filePickerCompletion in
                    filePicker.begin { response in
                        filePickerCompletion()
                        if response == .cancel {
                            removeStatusMsg(cloningStatusMsg)
                            deleteTempDir?()
                            completion()
                            return
                        }
                        assert(filePicker.urls.count == 1)
                        gotSourcesDirectory(sourcesDirectory: filePicker.urls[0])
                    }
                }  // end showFilePicker
            }
            
            
            
        }  // end sourceDirNames.count
        
    }  // end for loop

    
}


