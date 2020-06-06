//
//  GlobalEnvironment.swift
//  PackageManager
//
//  Created by Peter Schorn on 6/1/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import SwiftUI
import Utilities
import Combine
import Cocoa
import AppKit


// MARK: Notifications
extension Notification.Name {
    
    static let undo  = Notification.Name("undo")
    static let redo  = Notification.Name("redo")
    static let copy  = Notification.Name("copy")
    static let paste = Notification.Name("paste")
    static let clearStatusMsgs = Notification.Name("clearStatusMsgs")
    static let search = Notification.Name("search")
    static let deleteSelectedRepos = Notification.Name("deleteSelectedRepos")
    static let changeRepoName = Notification.Name("changeRepoName")
    static let openInBrowser = Notification.Name("openInBrowser")
    static let debug = Notification.Name("debug")
}



// MARK: Global Environment
class GlobalEnv: ObservableObject {
    
    @Published var searchText = ""

    @Published var saved_repos = getReposFromFile()
    
    @Published var repoSelections: Set<FilterResult> = []
    
    @Published var userSettings = UserDefaults.standard
    
    @Published var tempDirectories: [URL] = []
    
    @Published var statusMessages: [(message: String, isLoading: Bool, id: UUID)] = []
    
    @Published var cancelTaskCallbacks: [() -> Void] = []
    
    @Published var searchFieldInFocus = false
    
    // func filteredRepos() -> [String]
    
}
let globalEnv = GlobalEnv()


// MARK: Regex Options for Searching Repositories
/// .caseInsensitive, .ignoreMetacharacters
let searchRegexOptions: NSRegularExpression.Options = [
    .caseInsensitive, .ignoreMetacharacters
]


// MARK:  User Settings Keys
enum UserSettingsKeys: String {
    case playgroundsDir
}
