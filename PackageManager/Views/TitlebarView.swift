//
//  TitlebarView.swift
//  PackageManager
//
//  Created by Peter Schorn on 5/31/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation
import SwiftUI
import AppKit


struct TitlebarView: View {
    
    let pastePublisher = NotificationCenter.default.publisher(for: .paste)
    let copyPublisher = NotificationCenter.default.publisher(for: .copy)
    let openInBrowserPublisher = NotificationCenter.default.publisher(
        for: .openInBrowser
    )
    
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var globalEnv: GlobalEnv
    
    @State private var showCancelButton = false

    func pasteText() {
        guard globalEnv.searchFieldInFocus else { return }
    
        if let pastedText = pasteboardString() {
            globalEnv.searchText = pastedText
        }
    }
    
    func copyText() {
        guard globalEnv.searchFieldInFocus else { return }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(
            globalEnv.searchText, forType: .string
        )
        
    }
    
    func openInBrowser() {
        
        print("title bar: open in browser")
        for repo in self.globalEnv.repoSelections {
            if let url = URL(string: repo.url) {
                NSWorkspace.shared.open(url)
            }
        }

    }
    
    
    var darkMode: Bool { colorScheme == .dark }
    
    // MARK: - Body -
    var body: some View {

        HStack {
            
            TitleBarButton(view: Text("􀈑"), toolTip: "Delete") {
                NotificationCenter.default.post(
                    name: .deleteSelectedRepos, object: nil
                )
            }
            .disabled(self.globalEnv.repoSelections.isEmpty)
            
            
            TitleBarButton(view: Text("􀆪"), toolTip: "Open in browser") {
                self.openInBrowser()
            }
            .disabled(self.globalEnv.repoSelections.isEmpty)

            TitleBarButton(view: Text("􀈎"), toolTip: "Edit Repository Name") {
                print("title bar: edit repo name")
                NotificationCenter.default.post(
                    name: .changeRepoName, object: nil
                )
            }
            .disabled(globalEnv.repoSelections.count != 1)
            
            
            SearchBar(text: $globalEnv.searchText)
                .onReceive(pastePublisher) { _ in self.pasteText() }
                .onReceive(copyPublisher) { _ in self.copyText() }
                
        }
        .padding([.top], 8)
        .padding([.leading, .trailing], 5)
        .onReceive(openInBrowserPublisher) { _ in
            self.openInBrowser()
        }
        
        
    }
}


struct TitleBarButton<V: View>: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    init(view: V, toolTip: String = "", action: @escaping () -> Void) {
        self.view = view
        self.toolTip = toolTip
        self.action = action
    }

    let view: V
    let toolTip: String
    let action: () -> Void
    
    var body: some View {
        
        Button(action: action) {
            view
                .padding(3)
                .padding([.leading, .trailing], 5)
                .background(colorScheme == .dark ? Color(#colorLiteral(red: 0.443674624, green: 0.4360460639, blue: 0.4273921251, alpha: 1)) : Color(#colorLiteral(red: 0.9795874953, green: 0.9797278047, blue: 0.9795568585, alpha: 1)))
                .cornerRadius(4)
                .shadow(radius: 0.5)
                .shadow(radius: 0.5)
                .overlay(Tooltip(toolTip))
                
        }
        .buttonStyle(PlainButtonStyle())
        
    }
    
}



struct TitlebarView_Previews: PreviewProvider {
    static var previews: some View {
        // NSWindow
        TitlebarView()
            .environment(\.colorScheme, .light)
            .padding(5)
    }
}
