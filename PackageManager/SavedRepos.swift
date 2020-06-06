//
//  SavedRepos.swift
//  PlaygroundPackageManager
//
//  Created by Peter Schorn on 4/17/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation
import SwiftUI
import Utilities


struct SavedRepository: Codable, Hashable, Equatable {
    
    init(
        url: String,
        name: String? = nil,
        sourcesDir: String? = nil
    ) {
        self.name = name
        self.url = url
        self.sourcesDir = sourcesDir
        
        
    }
    
    let id = UUID()
    let url: String
    var name: String?
    var sourcesDir: String?
    
    enum CodingKeys: String, CodingKey {
        case url, name, sourcesDir
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
}

enum ChangeRepoOptions {
    case name(String)
    case sourcesDir(String)
}

func changeRepo(_ option: ChangeRepoOptions, id: UUID) {
    
    
    DispatchQueue.main.async {
        
        guard let indx = globalEnv.saved_repos.firstIndex(where: { repo in
            repo.id == id
        })
        else {
            return
        }
        
        switch option {
            case .name(let name):
                print("changing repo name to", name)
                globalEnv.saved_repos[indx].name = name
            case .sourcesDir(let dir):
                print("changing repo sources dir to", dir)
                globalEnv.saved_repos[indx].sourcesDir = dir
        
                print("func changeRepo \(option)")
                saveReposToFile(globalEnv.saved_repos)
        }
        
        
    }
}

func repoInfoFromURL(url: String) -> SavedRepository? {
    
    for repo in globalEnv.saved_repos {
        if repo.url == url {
            return repo
        }
    }
    return nil
    
}


func getSavedReposPath() -> URL {
    
    // let repoURL = FileManager.default.urls(
    //     for: .documentDirectory, in: .userDomainMask
    // ).first!
    
    var repoURL = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
    ).first!
    
    repoURL.appendPathComponent(
        "PlaygroundPackageManager", isDirectory: true
    )
    
    if !isExistingDirectory(repoURL) {
        
        try! FileManager.default.createDirectory(
            at: repoURL,
            withIntermediateDirectories: true
        )
    }
    
    repoURL.appendPathComponent(
        "repositories.json", isDirectory: false
    )
    
    
    // print("saved repositories url:", repoURL.absoluteString)
    return repoURL
}



func saveReposToFile(_ repos: [SavedRepository]) {
        
    print("saving repositories to file")
    
    guard let jsonData = try? JSONEncoder().encode(repos) else {
        assertionFailure("\nsaveReposToFile: couldn't encode repos to JSON data\n\n")
        return
    }
    
    let repoURL = getSavedReposPath()
    
    
    do {
        try jsonData.write(to: repoURL)
    }
    catch {
        print("error writing json data to file:\n")
        assertionFailure(error.localizedDescription)
    }
    
    
}

func getReposFromFile() -> [SavedRepository] {
    
    let repoURL = getSavedReposPath()
    
    do {
        if FileManager.default.fileExists(atPath: repoURL.path) {
            // print("getReposFromFile: found file")
            
            let loadedRepos = try loadJSONFromFile(
                url: repoURL, type: [SavedRepository].self
            )
        
            return loadedRepos
        }
    
    } catch {
        print(error)
        assertionFailure("getReposFromFile: file exists, but couldn't decode into json")
    }
    
    print(
        """
        getReposFromFile: couldn't find file.
        Ignore this error if this app is being run for the first time
        """
    )
    
    return []
}



func deleteTemporayDirectories() {
    
    for tempDir in globalEnv.tempDirectories {
        print("deleting temporary directory:", tempDir.path)
        do {
            try FileManager.default.removeItem(at: tempDir)
            
        } catch {
            print("error deleting temporary directory:")
            print(error)
        }
    }
    
    
}
