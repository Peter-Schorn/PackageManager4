//
//  AddURLSheet.swift
//  PlaygroundPackageManager
//
//  Created by Peter Schorn on 4/26/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import SwiftUI
import Utilities

struct GeneralSheet: View {
    
    init(
        isPresented: Binding<Bool>,
        title: Binding<String>,
        url: Binding<String>? = nil,
        textFieldHint: String = "",
        textField: Binding<String>,
        rightButtonText: String,
        selectedCancel: @escaping () -> Void,
        selectedDone: @escaping () -> Void
    ) {
        
        self._isPresented = isPresented
        self._title = title
        self._url = url ?? Binding.constant("")
        self.textFieldHint = textFieldHint
        self._textField = textField
        self.rightButtonText = rightButtonText
        self.selectedCancel = selectedCancel
        self.selectedDone = selectedDone
    }
    
    let pastePublisher = NotificationCenter.default.publisher(for: .paste)
    
    @EnvironmentObject var globalEnv: GlobalEnv
    
    let textFieldHint: String
    let rightButtonText: String
    
    let selectedCancel: () -> Void
    let selectedDone: () -> Void

    @State private var isHoveringOverURL = false
    
    @Binding var title: String
    @Binding var url: String
    @Binding var textField: String
    @Binding var isPresented: Bool
    
    
    func pasteFromClipboard() {
        
        if !isPresented {
            print("General Sheet tried to paste but not showing")
            return
        }
        
        print("General Sheet: pasteFromClipboard")
        
        if let pastedText = pasteboardString() {
            textField = pastedText
        }
    }
    
    var body: some View {
        VStack {
            
            Text(title)
                .padding(5)
            
            // MARK: URL
            HyperLink(
                link: URL(string: self.url),
                displayText: Text(self.url).font(.caption)
            )
            .onExitCommand(perform: selectedDone)
            .lineLimit(3)
            
            TextField(textFieldHint, text: $textField)
                .onExitCommand(perform: selectedDone)
                .onReceive(self.pastePublisher) { _ in
                    self.pasteFromClipboard()
                }
            
            HStack {
                Spacer()
                // MARK: Cancel Button
                Button(action: {
                    self.selectedCancel()
                }) {
                    Text("Cancel")
                }
                .onExitCommand(perform: selectedDone)
                // MARK: Right Button
                DefaultButton(
                    rightButtonText, keyEquivalent: .return,
                    action: selectedDone
                )
                .disabled(textField.isEmpty)
                .onExitCommand(perform: selectedDone)
                
            }
            
            
        }
        .padding([.leading, .trailing])
        // .frame(width: 420, height: 120)
        // .frame(minWidth: 420, minHeight: 120)
        .frame(
            minWidth: 420, idealWidth: 420,
            minHeight: 150, idealHeight: 150
        )
        
    }  // end body
}



struct GeneralSheet_Previews: PreviewProvider {
    
    static let shortURL = "https://github.com/apple/swift-numerics"
    static let longURL =
        "https://github.com/Peter-Schorn/Play-Spotify-Songs-from-Spotlight-Search" +
        "-and-some-even-more-text-that-makes-this-link-really-long"
    
    static var previews: some View {
        GeneralSheet(
            isPresented: .constant(true),
            title: .constant("Change Repository Name"),
            url: .constant(shortURL),
            textField: .constant(""),
            rightButtonText: "Finished",
            selectedCancel: { print("user selected cancel") },
            selectedDone: { print("user selected done") }
        )
        .frame(
            width: 420, height: 150
        )
    }
}

