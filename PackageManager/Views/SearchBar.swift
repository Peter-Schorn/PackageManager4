//
//  SearchBar.swift
//  PackageManager
//
//  Created by Peter Schorn on 6/1/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import SwiftUI
import Combine
import AppKit

struct SearchBar: NSViewRepresentable {

    @Binding var text: String
    
    class Coordinator: NSObject, NSSearchFieldDelegate {

        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }
        
        
        
        
        func controlTextDidChange(_ obj: Notification) {
            // print("controlTextDid CHANGE")
            if let searchBar = obj.object as? NSSearchField {
                text = searchBar.stringValue
                globalEnv.searchFieldInFocus = searchBar.hasKeyboardFocus()
                
                globalEnv.globalFilteredRepos = globalEnv.filterRepos()
                globalEnv.fixRepoSelections()
                // if searchBar.currentEditor() == nil {
                //     print("search field is out of focus")
                // }
                // else {
                //     print("search field is in focus")
                // }
            }
            
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            // print("controlTextDid END Editing")
            // if let searchBar = obj.object as? NSSearchField {
            //     globalEnv.searchFieldInFocus = searchBar.hasKeyboardFocus()
            //     if searchBar.currentEditor() == nil {
            //         print("search field is out of focus")
            //     }
            //     else {
            //         print("search field is in focus")
            //     }
            // }
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            // print("controlTextDid BEGIN Editing")
            // if let searchBar = obj.object as? NSSearchField {
            //     globalEnv.searchFieldInFocus = searchBar.hasKeyboardFocus()
            //     if searchBar.currentEditor() == nil {
            //         print("search field is out of focus")
            //     }
            //     else {
            //         print("search field is in focus")
            //     }
            // }
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(notificationHandler(_:)),
                name: NSControl.textDidEndEditingNotification,
                object: nil
            )
            
            
        }
        
        
        @objc func notificationHandler(_ obj: Notification) {
            
            // print("\nreceived notification\n")
            // if let searchBar = obj.object as? NSSearchField {
            //     globalEnv.searchFieldInFocus = searchBar.hasKeyboardFocus()
            //     if searchBar.currentEditor() == nil {
            //         print("search field is out of focus")
            //     }
            //     else {
            //         print("search field is in focus")
            //     }
            // }
            // print()
        }
        
        
    }

    func makeCoordinator() -> SearchBar.Coordinator {
        return Coordinator(text: $text)
    }

    func makeNSView(
        context: NSViewRepresentableContext<SearchBar>
    ) -> NSSearchField {
        
        let searchBar = NSSearchField(frame: .zero)
        searchBar.delegate = context.coordinator
        
        return searchBar
    }

    func updateNSView(
        _ searchBar: NSSearchField,
        context: NSViewRepresentableContext<SearchBar>
    ) {
        
        searchBar.stringValue = text
    }
}



extension NSSearchField {

    public func hasKeyboardFocus() -> Bool {

        if let editor = self.currentEditor(),
            editor == self.window?.firstResponder {
            // print("search bar is in focus")
            return true
        }
        // print("search bar is out of focus")
        return false

    }

}



struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(text: .constant("Peter Schorn"))
    }
}
