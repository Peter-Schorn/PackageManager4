//
//  AppDelegate.swift
//  PlaygroundPackageManager
//
//  Created by Peter Schorn on 4/17/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import SwiftUI
import Utilities
import Combine
import Cocoa
import AppKit


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Menu Bar Actions -
    
    @IBAction func menuBarUndo(_ sender: Any) {
        NotificationCenter.default.post(name: .undo, object: nil)
    }
    
    @IBAction func menuBarRedo(_ sender: Any) {
        NotificationCenter.default.post(name: .redo, object: nil)
    }
    
    @IBAction func menuBarSave(_ sender: Any) {
        saveReposToFile(globalEnv.saved_repos)
    }
    
    @IBAction func menuBarShowSavedRepos(_ sender: Any) {
        
        // print("menuBarShowSavedRepos")
        let reposURL = getSavedReposPath()
        NSWorkspace.shared.activateFileViewerSelecting([reposURL])
        
    }
    
    @IBAction func menuBarCopy(_ sender: Any) {
        NotificationCenter.default.post(name: .copy, object: nil)
    }
    
    @IBAction func menuBarPaste(_ sender: Any) {
        NotificationCenter.default.post(name: .paste, object: nil)
    }
    
    
    @IBAction func menuBarClearOutput(_ sender: Any) {
        NotificationCenter.default.post(name: .clearStatusMsgs, object: nil)
    }
    
    @IBAction func menuBarSearch(_ sender: Any) {
        NotificationCenter.default.post(name: .search, object: nil)
    }
    
    
    @IBAction func menuBarEditRepoName(_ sender: Any) {
        NotificationCenter.default.post(name: .changeRepoName, object: nil)
    }
    
    
    @IBAction func menuBarOpenInBrowser(_ sender: Any) {
        NotificationCenter.default.post(name: .openInBrowser, object: nil)
    }
    
    
    @IBAction func menuBarDebug(_ sender: Any) {
        NotificationCenter.default.post(name: .debug, object: nil)
    }
    
    
    @IBAction func menuBarSelectPlaygrounds(_ sender: Any) {
        NotificationCenter.default.post(name: .selectPlaygrounds, object: nil)
    }
    
    @IBAction func menuBarAddRepo(_ sender: Any) {
        NotificationCenter.default.post(name: .addRepo, object: nil)
    }
    
    
    var window: NSWindow!

    func applicationDidFinishLaunching(_ Notification: Notification) {
        
        
        // MARK: - Instantiate Root View -
        let rootView = RootView()
            .environmentObject(globalEnv)
            .frame(
                minWidth: 500,  idealWidth: 600,  maxWidth: .infinity,
                minHeight: 500, idealHeight: 600, maxHeight: .infinity
            )
            
        
        
        // MARK: Setup Toolbar
        let titleBarView = TitlebarView()
            .padding(.top, 16)
            .padding([.leading, .trailing], 5)
            .padding(.bottom, -8)
            .edgesIgnoringSafeArea(.top)
            .environmentObject(globalEnv)
            
        
        let accessoryHostingView = NSHostingView(rootView: titleBarView)
        accessoryHostingView.frame.size = accessoryHostingView.fittingSize
        
        let titlebarAccessory = NSTitlebarAccessoryViewController()
        titlebarAccessory.view = accessoryHostingView
        
        

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false
        )
        window.center()
        window.setFrameAutosaveName("Main Window")
        // MARK: add toolbar to window
        window.addTitlebarAccessoryViewController(titlebarAccessory)
        window.contentView = NSHostingView(rootView: rootView)
        window.makeKeyAndOrderFront(nil)
        window.title = "Playground Package Manager"
        
        
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        saveReposToFile(globalEnv.saved_repos)
        deleteTemporayDirectories()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        
        return true
    }


}
