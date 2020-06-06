//
//  AddURLSheet.swift
//  PlaygroundPackageManager
//
//  Created by Peter Schorn on 4/26/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import SwiftUI
import AppKit
import Utilities


struct AddRepoSheet: View {
    
    let pastePublisher = NotificationCenter.default.publisher(for: .paste)
    
    @EnvironmentObject var globalEnv: GlobalEnv
    
    @State var newURL = ""
    @State private var newName = ""
    @State private var alertIsPresented = false
    @State private var currenTextField = CurrenTextField.none
    @Binding var isPresented: Bool
    
    enum CurrenTextField {
        case newURL, newName, none
    }
    
    
    let dismissCallback: () -> Void
    
    func pastFromClipboard() {
       
        print("pastFromClipboard")
        
        guard let pastedText = NSPasteboard.general.string(forType: .string) else {
            print("couldn't get text from clipboard")
            return
        }
        
        print("got text from clipboard:", pastedText)
        
        switch currenTextField {
            case .newURL:
                print("case .newURL")
                if URL(string: pastedText) == nil {
                    print("AddURLSheet: returning because pasted text is not url")
                    return
                }
                newURL = pastedText
            case .newName:
                print("case .newName")
                newName = pastedText
            case .none:
                print("no text field selected")
                break
        }
        
    }
    
    func doneEnteringText() {
        
        print("doneEnteringText")
        
        if !self.newURL.hasPrefix("https://") {
            self.newURL = "https://" + self.newURL
        }

        if self.globalEnv.saved_repos.any({ savedRepo in
            savedRepo.url == self.newURL
        }) {
            self.alertIsPresented = true
        }
        else {
            self.globalEnv.saved_repos.append(
                SavedRepository(url: self.newURL, name: self.newName)
            )
            print(self.globalEnv.saved_repos[back: 1])
            saveReposToFile(self.globalEnv.saved_repos)
        }
        self.newURL = ""
        self.newName = ""
        self.dismissCallback()
    }
    
    var body: some View {
        VStack {
            
            // MARK: - Add URL -
            Text("Add Repository")
                .padding(5)
            
            HStack {
                Text("URL")
                    .font(.caption)
                    .frame(width: 35)
                TextField("", text: $newURL)
                    .onExitCommand(perform: doneEnteringText)
                    .focusable(true) { inFocus in
                        print("newURL field in focus:", inFocus)
                        if inFocus {
                            self.currenTextField = .newURL
                        }
                    }
            }
            HStack {
                Text("Name")
                    .font(.caption)
                    .frame(width: 35)
                TextField("", text: $newName)
                    .onExitCommand(perform: doneEnteringText)
                    .focusable(true) { inFocus in
                        print("newName field in focus:", inFocus)
                        if inFocus {
                            self.currenTextField = .newName
                        }
                    }
            }
            
            HStack {
                Spacer()
                Button(action: {
                    self.newURL = ""
                    self.dismissCallback()
                }) {
                    Text("Cancel")
                }
                .onExitCommand(perform: doneEnteringText)
                
                DefaultButton(
                    "Add", keyEquivalent: .return,
                    action: doneEnteringText
                )
                .onExitCommand(perform: doneEnteringText)
                .disabled(self.newURL.isEmpty)
                
            }
            .onReceive(self.pastePublisher) { _ in
                self.pastFromClipboard()
            }
            
        }
        .onExitCommand(perform: doneEnteringText)
        .padding([.leading, .trailing])
        .frame(width: 420, height: 140)
        
        .alert(isPresented: self.$alertIsPresented) {
            Alert(
                title: Text("This URL has already been added"),
                dismissButton: .default(Text("OK"))
            )
        }
        
    }  // end body
}




struct AddURLSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddRepoSheet(
            isPresented: .constant(true),
            dismissCallback: { print("dismissed ")}
        )
        .environmentObject(globalEnv)
    }
}
