//
//  RootViewFunctions.swift
//  PackageManager
//
//  Created by Peter Schorn on 5/30/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Cocoa
import SwiftUI
import Foundation
import Utilities
import Combine

extension RootView {
    
    /// If specificRepo is nil, then the currently selected
    /// repositories are deleted.
    func deleteReposFromList(_ specificRepo: String? = nil) {
        
        
        let currentRepos = self.globalEnv.saved_repos
        
        undoStack.addUndoAction {
            self.globalEnv.saved_repos = currentRepos
            saveReposToFile(self.globalEnv.saved_repos)
        }
            
        
        self.globalEnv.saved_repos.removeAll(where: { repo in
            if let specificRepo = specificRepo {
                return repo.url == specificRepo
            }
            else {
                if globalEnv.repoSelections.map({ $0.url }).contains(repo.url) {
                    print("removing:", repo.url)
                    return true
                }
                print("not removing:", repo.url)
                return false
            }
        })
        
        self.globalEnv.updateRepos()
        self.globalEnv.fixRepoSelections()
        
        saveReposToFile(self.globalEnv.saved_repos)
        
        
        

    }
    
    func setupFilePicker() {
        // filePicker.title = "Choose a Playground"
        filePicker.showsResizeIndicator = true
        filePicker.showsHiddenFiles = false
        filePicker.canChooseFiles = true
        filePicker.canChooseDirectories = false
        filePicker.allowsMultipleSelection = true
        filePicker.allowedFileTypes = ["playground"]
        filePicker.prompt = "Choose"
        filePicker.directoryURL = self.globalEnv.userSettings.url(
            forKey: UserSettingsKeys.playgroundsDir.rawValue
        )
        
        // print("filePicker directory url was set to")
        print(filePicker.directoryURL ?? "nil")
        
    }
    
    func pressedUndo() {
        let currentRepos = self.globalEnv.saved_repos
        self.undoStack.undo {
            self.globalEnv.saved_repos = currentRepos
            saveReposToFile(self.globalEnv.saved_repos)
        }
        saveReposToFile(self.globalEnv.saved_repos)
    }
    
    func pressedRedo() {
        let currentRepos = self.globalEnv.saved_repos
        self.undoStack.redo {
            self.globalEnv.saved_repos = currentRepos
            saveReposToFile(self.globalEnv.saved_repos)
        }
        saveReposToFile(self.globalEnv.saved_repos)
    }
    
    func copyToClipboard(_ text: String) {
        print("copying to clipboard with text", text)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    
    func pasteFromClipboard() {
        
        if any(
            addURLSheetIsPresented,
            getRepoNameIsShowing,
            changeRepoNameIsShowing,
            globalEnv.searchFieldInFocus
        ) {
            return
        }
        
        
        
        print("should paste from clipboard")
        
        guard var pastedText = NSPasteboard.general.string(forType: .string) else {
            print("couldn't get text from clipboard")
            return
        }
        
        if URL(string: pastedText) == nil { return }
        
        if !pastedText.hasPrefix("https://") {
            pastedText = "https://" + pastedText
        }
        
        if self.globalEnv.saved_repos.any({ $0.url == pastedText}) {
            alertTitle = "This URL has already been added:"
            alertMsg = pastedText
            showingErrorAlert = true
        }
        else {
            self.globalEnv.saved_repos.append(SavedRepository(url: pastedText))
            saveReposToFile(self.globalEnv.saved_repos)
        }
        
        globalEnv.updateRepos()
        
    }
    
    func finishedAddingReposToPlaygrounds() {
        
        let currentMsgIds = self.globalEnv.statusMessages.map { $0.id }
        
        // Remove all of the current status messages after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.globalEnv.statusMessages.removeAll { msg in
                currentMsgIds.contains(msg.id)
            }
        }
    }
        
    func showAlertCallback(title: String, msg: String) {
        DispatchQueue.main.async {
            print("Root View: showAlertCallback:")
            print("title:", title)
            print("msg:", msg)
            self.alertTitle = title
            self.alertMsg = msg
            self.showingErrorAlert = true
        }
    }
    
    // MARK: Need Repository Name
    func getRepoName(
        repoURL: String,
        cloningStatusMsg: UUID,
        gotName: @escaping (_ name: String) -> Void
    ) {
    
        print("getRepoName: presenting sheet")
    
        // getRepoNameTitleField = "Enter the name of the repository for\n\(repoURL)"
        
        // DispatchQueue.main.async {
            self.presentSheet(.getRepoName(
                url: repoURL, cloningMsg: cloningStatusMsg, gotTextHandler: gotName
            ))
            
        // }
        
        
    }
    
    
    func selectPlaygroundsButtonAction() {
        
        // self.globalEnv.fixRepoSelections()
        
        if globalEnv.repoSelections.isEmpty { return }
        
        self.selectPlaygroundIsShowing = true
        
        self.setupFilePicker()
        
        let repoGrammar = globalEnv.repoSelections.count == 1 ? "y" : "ies"
        self.filePicker.message =
                "Choose the Playrounds to add the repositor\(repoGrammar) to"

        self.filePicker.begin { response in
            
            self.selectPlaygroundIsShowing = false
            
            if response == .cancel { return }

            self.globalEnv.userSettings.set(
                self.filePicker.directoryURL,
                forKey: .playgroundsDir
            )
            
            let setOfRepos = Set(self.globalEnv.saved_repos.filter({ repo in
                self.globalEnv.repoSelections.map { $0.url }.contains(repo.url)
            }))
            
            print("will choose playgrounds: selected repos:")
            for repo in setOfRepos {
                print(repo.url)
            }
            print()
        
            
            // MARK: - Did Choose Playgrounds -
            didChoosePlaygrounds(
                playgrounds: self.filePicker.urls,
                repos: setOfRepos,
                alertCallback: self.showAlertCallback(title:msg:),
                needRepoName: self.getRepoName(repoURL:cloningStatusMsg:gotName:),
                showFilePicker: self.showSourceFilePicker(_:),
                completion: self.finishedAddingReposToPlaygrounds
            )
        }
        
    }
    
    func showSourceFilePicker(
        _ show: @escaping (_ completion: @escaping () -> Void) -> Void
    ) {
        // _ = show
        // self.presentSheet(.showFilePicker(show: show))
        // presentSheet(.showFilePicker(present: show))
        DispatchQueue.main.async {
            print("appending show source file picker to queue")
            self.presentSheetQueue.append {
                self.sheetIsPresented = true
                show() {
                    print("\n\ninside finished filepicker handler: dismissing\n\n")
                    self.dissmissSheet(.dismissFilePicker)
                }
            }
            
            if !self.sheetIsPresented {
                self.sheetIsPresented = true
                print("presenting file picker immediately")
                self.presentSheetQueue.removeFirst()()
            }
            else {
                print("appended picker to queue; count:", self.presentSheetQueue.count)
            }
            
        }
        
    
    }
    
    
    enum Sheets {
        case addNewURL
        case getRepoName(url: String, cloningMsg: UUID, gotTextHandler: ((String) -> Void)?)
        case dismissGetRepoName
        case changeRepoName
        case couldnotConvertToURL
        case dismissFilePicker
        // case filePicker(completion: (NSApplication.ModalResponse) -> Void)
    }
    
    func presentSheet(_ sheet: Sheets) {
        
        DispatchQueue.main.async {
        
            print("func presentSheet")
            
            switch sheet {
                case .addNewURL:
                    self.presentSheetQueue.append {
                        self.sheetIsPresented = true
                        self.addURLSheetIsPresented = true
                    }
                // MARK: Special Async
                case let .getRepoName(url, cloningMsg, gotText):
                    self.presentSheetQueue.append {
                        DispatchQueue.main.async {
                            self.sheetIsPresented = true
                            self.currentSheetStatusMsg = cloningMsg
                            self.getRepoNameURL = url
                            self.gotTextHandler = gotText
                            self.getRepoNameIsShowing = true
                            print("presentSheet: switch: .getRepoName: gotTextHandler:")
                            print(self.gotTextHandler as Any)
                            print("url:", url)
                        }
                    }
                case .changeRepoName:
                    self.presentSheetQueue.append {
                        self.sheetIsPresented = true
                        self.changeRepoNameIsShowing = true
                    }
                case .couldnotConvertToURL:
                    self.presentSheetQueue.append {
                        self.sheetIsPresented = true
                        self.couldntConvertURLIsShowing = true
                    }
                case .dismissFilePicker:
                    assertionFailure(
                        "Sheets.dismissFilePicker " +
                        "should only be used to dismiss the file picker"
                    )
                case .dismissGetRepoName:
                    assertionFailure(
                        "Sheets.dismissGetRepoName " +
                        "should only be used to dismiss the sheet"
                    )
            }
            
            // if the only sheet in the queue is the one
            // that was just added, then present it immediately.
            if !self.sheetIsPresented {
                self.sheetIsPresented = true
                print("presenting sheet immediately")
                self.presentSheetQueue.removeFirst()()
            }
            else {
                print("appended sheet to queue; count:", self.presentSheetQueue.count)
            }
            
        }
    }
    
    func dissmissSheet(_ sheet: Sheets) {
        
        DispatchQueue.main.async {
        
            print("func dissmissSheet")
            self.globalEnv.updateRepos()

            switch sheet {
                case .addNewURL:
                    self.addURLSheetIsPresented = false
                case .dismissGetRepoName:
                    self.getRepoNameIsShowing = false
                case .changeRepoName:
                    self.changeRepoNameIsShowing = false
                case .couldnotConvertToURL:
                    self.couldntConvertURLIsShowing = false
                case .dismissFilePicker:
                    print("func dismissSheet: case .dismissFilePicker")
                    break
                case .getRepoName(_, _, _):
                    assertionFailure(
                        "Sheets.getRepoName should only " +
                        "be used for presenting sheets"
                    )
                
            }

            
            
            // present the next sheet after the previous was dismissed
            print("after dismissing sheet:", terminator: " ")
            if !self.presentSheetQueue.isEmpty {
                print("presenting next one")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.presentSheetQueue.removeFirst()()
                }
            }
            else {
                self.sheetIsPresented = false
                print("no other sheets to present")
            }
        
        }
        
    }
    
    
}
