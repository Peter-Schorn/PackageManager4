//
//  ContentView.swift
//  PlaygroundPackageManager
//
//  Created by Peter Schorn on 4/17/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Cocoa
import SwiftUI
import Foundation
import Utilities
import Combine

struct RootView: View {
    
    
    // MARK: Notifcation Center Publishers
    let undoPublisher = NotificationCenter.default.publisher(for: .undo)
    let redoPublisher = NotificationCenter.default.publisher(for: .redo)
    let copyPublisher = NotificationCenter.default.publisher(for: .copy)
    let pastePublisher = NotificationCenter.default.publisher(for: .paste)
    let clearStatusMsgsPublisher = NotificationCenter.default.publisher(
        for: .clearStatusMsgs
    )
    let searchPublisher = NotificationCenter.default.publisher(for: .search)
    let deleteSelectedReposPublisher = NotificationCenter.default.publisher(
        for: .deleteSelectedRepos
    )
    let changeRepoNamePublisher = NotificationCenter.default.publisher(
        for: .changeRepoName
    )
    let debugPublisher = NotificationCenter.default.publisher(
        for: .debug
    )
    
    // MARK: Environment
    @EnvironmentObject var globalEnv: GlobalEnv
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    @State var showingErrorAlert = false
    @State var alertTitle = ""
    @State var alertMsg = ""
    
    // MARK: View Sheets
    @State var sheetIsPresented = false
    
    @State var addURLSheetIsPresented = false
    
    @State var getRepoNameIsShowing = false
    
    @State var getRepoNameTitleField = "Enter the name for this repository:"
    @State var getRepoNameURL = ""
    
    @State var getrepoNameField = ""
    
    
    @State var changeRepoNameIsShowing = false
    @State var changeRepoNameField = ""

    @State var couldntConvertURLIsShowing = false
    
    @State var selectPlaygroundIsShowing = false
    
    // MARK: End View Sheets

    @State var rightClickedRepo: SavedRepository? = nil
    
    @State var currentSheetStatusMsg: UUID? = nil
    
    @State var gotTextHandler: ((_ name: String) -> Void)? = nil   // {


    @State var presentSheetQueue: [() -> Void] = []

    let undoStack = UndoRedoManager()
    let filePicker = NSOpenPanel()
    
    var darkMode: Bool { colorScheme == .dark }

    // MARK: Repository Selections
    // @State var repoSelections: Set<FilterResult> = []

    
    // MARK: - Body -
    var body: some View {
        
        VStack {

            // MARK: - List of Repositories -
            VSplitView {
                ZStack {
                    List(
                        self.globalEnv.filteredRepos(),
                        id: \.self, selection: $globalEnv.repoSelections
                    ) { repo in
                        
                        // Text(repo.url)
                        StyledText(repo.url)
                        .style(TextStyle(key: .init("highlight"), apply: { text in
                            text
                            .foregroundColor(self.darkMode ? Color(#colorLiteral(red: 0.9529411793, green: 0.8364016612, blue: 0.1843847989, alpha: 1)) : Color(#colorLiteral(red: 0.992759645, green: 0.7715821862, blue: 0, alpha: 1)))
                    
                        }), ranges: { _ in
                            repo.attributeRanges.map { Optional($0) }
                        })
                        
                        .overlay(Tooltip(repoInfoFromURL(url: repo.url)?.name ?? ""))
                        .contextMenu {
                            Text(repoInfoFromURL(url: repo.url)?.name ?? "no name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Button(action: {
                                
                                print("selected change repo name context menu")
                                self.rightClickedRepo = repoInfoFromURL(url: repo.url)
                                if self.rightClickedRepo != nil {
                                    self.presentSheet(.changeRepoName)
                                }
                            }) {
                                Text("Edit Repository Name")
                            }
                            .disabled(
                                self.sheetIsPresented ||
                                self.selectPlaygroundIsShowing
                            )
                            Button(action: {
                                self.presentSheet(.couldnotConvertToURL)
                                if let url = URL(string: repo.url) {
                                    NSWorkspace.shared.open(url)
                                }
                                else {
                                    self.couldntConvertURLIsShowing = true
                                }
                            }) {
                                Text("View in Browser")
                            }
                            Button(action: {
                                self.copyToClipboard(repo.url)
                        
                            }) {
                                Text("Copy URL")
                            }
                            Button(action: {
                                self.deleteReposFromList(repo.url)
                            }) {
                                Text("Delete")
                            }
                        }
                        

                    }  // end list body
                    .onDeleteCommand { self.deleteReposFromList() }
                    if self.globalEnv.saved_repos.isEmpty {
                        Text(
                            """
                            Click "Add URL" to add a repository to the list. \
                            Select one or more repositories from the list, \
                            then click "Select Playgounds" to choose \
                            the playgrounds you want to add the repositories to. \
                            You may add multiple repositories \
                            to multiple playgrounds at the same time. \
                            Right-click on a repository for more options. \
                            To see where the repositories are saved in finder, \
                            select File > Show Saved Repositories in Finder.
                            """
                        )
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    }
                }  // end ZStack
                .frame(minHeight: 175, idealHeight: 200)
                .onReceive(deleteSelectedReposPublisher) { _ in
                    self.deleteReposFromList()
                }
                .onReceive(undoPublisher) { _ in self.pressedUndo() }
                .onReceive(redoPublisher) { _ in self.pressedRedo() }
                .onReceive(pastePublisher) { _ in self.pasteFromClipboard() }
                .onReceive(copyPublisher) { _ in
                    self.copyToClipboard(
                        self.globalEnv.repoSelections.map { $0.url }
                                .joined(separator: " ")
                    )
                }
                .onReceive(changeRepoNamePublisher) { _ in
                    if self.globalEnv.repoSelections.count != 1 {
                        return
                    }
                    self.rightClickedRepo = repoInfoFromURL(
                        url: self.globalEnv.repoSelections.randomElement()!.url
                    )
                    self.presentSheet(.changeRepoName)
                    
                    
                }
                    
                .cornerRadius(3)
                .padding([.leading, .trailing, .top], 10)
                .padding(.bottom, 5) //
                .alert(isPresented: self.$couldntConvertURLIsShowing) {
                    Alert(
                        title: Text("Couldn't convert text to URL"),
                        dismissButton: .default(Text("OK"))
                    )
                }
                // MARK: - Change Repository Name Sheet
                .sheet(isPresented: self.$changeRepoNameIsShowing) {
                    GeneralSheet(
                        isPresented: self.$changeRepoNameIsShowing,
                        title: .constant("Enter The Name of the Repository"),
                        textField: self.$changeRepoNameField,
                        rightButtonText: "Done",
                        selectedCancel: {
                            self.changeRepoNameField = ""
                            self.dissmissSheet(.changeRepoName)
                        },
                        selectedDone: {
                            let name = self.changeRepoNameField
                            self.changeRepoNameField = ""
                            self.dissmissSheet(.changeRepoName)
                            if let repo = self.rightClickedRepo {
                                changeRepo(.name(name), id: repo.id)
                            }
                        }
                    )
                    .environmentObject(self.globalEnv)
                }

            
                    
            // MARK: - Status Messages -
            
                List(self.globalEnv.statusMessages, id: \.id) { msg in
                    GeometryReader { geo in
                        HStack {
                            if msg.isLoading {
                                ActivityIndicator(
                                    shouldAnimate: .constant(msg.isLoading),
                                    style: .spinning
                                )
                                .frame(
                                    width: geo.size.height,
                                    height: geo.size.height
                                )
                            }
                            else {
                                Image(.checkMark)
                                .resizable()
                                .frame(
                                    width: geo.size.height * 1.2,
                                    height: geo.size.height * 1.2
                                )
                                .blur(radius: 0.1)
                                .animation(.easeInOut(duration: 0.5))
                            }
                            Text(msg.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                
                }
                .colorMultiply(Color(#colorLiteral(red: 0.5182887248, green: 0.6359114107, blue: 0.6388193965, alpha: 1))).padding(.top)
                .padding([.leading, .trailing], 10)
                // .padding(.bottom, 5)
                .contextMenu {
                    Button(action: {
                        removeAllStatusMsgs()
                    }) {
                        Text("Clear Status Messages")
                    }.disabled(self.globalEnv.statusMessages.isEmpty)
                }
                .frame(minHeight: 150)
                
            }
            
            
            // MARK:  - Begin Select Playgrounds and New URL Button -
                    
            .onReceive(clearStatusMsgsPublisher) { _ in
                removeAllStatusMsgs()
                print("menu bar clear status messages")
            }
            // MARK: - Add URL Sheet
            .sheet(isPresented: self.$addURLSheetIsPresented) {
                AddURLSheet(
                    isPresented: self.$addURLSheetIsPresented,
                    dismissCallback: { self.dissmissSheet(.addNewURL) }
                )
                .environmentObject(self.globalEnv)
            }
            
            HStack {
                
                // MARK: Select Playground Button
                Button(action: selectPlaygroundsButtonAction) {
                    Text("Select Playgrounds")
                }
                .disabled(
                    self.globalEnv.saved_repos.isEmpty ||
                    globalEnv.repoSelections.isEmpty ||
                    sheetIsPresented ||
                    selectPlaygroundIsShowing
                )
                // MARK: Error Alert From didChoosePlaygrounds
                .alert(isPresented: self.$showingErrorAlert) {
                    Alert(
                        title: Text(self.alertTitle),
                        message: Text(self.alertMsg),
                        dismissButton: .default(Text("OK"))
                    )
                }
                // MARK: Add New Repository Button
                Button(action: {
                    self.presentSheet(.addNewURL)
                }) {
                    Text("Add Repository")
                }
                .disabled(
                    sheetIsPresented ||
                    selectPlaygroundIsShowing
                )
                // MARK: Cancel All Repo Cloning
                if !globalEnv.cancelTaskCallbacks.isEmpty {
                    Button(action: {
                        print("cancelling tasks")
                        self.finishedAddingReposToPlaygrounds()
                        for cancelTask in self.globalEnv.cancelTaskCallbacks {
                            cancelTask()
                        }
                        self.globalEnv.cancelTaskCallbacks.removeAll()
                        
                    }) {
                        Text("Cancel All")
                    }
                }
  
                
            }  // end HStack for select playground, url, and cancel all buttons
            .padding(.bottom, 10)
            // MARK: - Get Repository Name Sheet -
            .sheet(isPresented: self.$getRepoNameIsShowing) {
                GeneralSheet(
                    isPresented: self.$getRepoNameIsShowing,
                    title: .constant("Enter the Name of this Repository:"),
                    url: self.$getRepoNameURL,
                    textField: self.$getrepoNameField,
                    rightButtonText: "Done",
                    selectedCancel: {
                        if let statusMsg = self.currentSheetStatusMsg {
                            print("Get repo name sheet selected cancel, removing status msg")
                            removeStatusMsg(statusMsg)
                        }
                        self.getrepoNameField = ""
                        print("user cancelled entering name")
                        self.dissmissSheet(.dismissGetRepoName)
                    },
                    selectedDone: {
                        // MARK: User pressed done; send name to handler
                        print(
                            """
                            ------------------------------------------
                            User pressed done for get repo name sheet;
                            Name: \(self.getrepoNameField)
                            ------------------------------------------
                            """
                        )
                        if self.gotTextHandler == nil {
                            print(
                                """
                                ------------------------------------------
                                ------------------------------------------
                                WARNING: GotTextHanlder is nil
                                getrepoNameField: \(self.getrepoNameField)
                                ------------------------------------------
                                ------------------------------------------
                                """
                            )
                        }
                        self.gotTextHandler?(self.getrepoNameField)
                        self.getrepoNameField = ""
                        self.dissmissSheet(.dismissGetRepoName)
                    }
                )
                .environmentObject(self.globalEnv)
            }
            
            
        }  // end VStack for entire body
        .background(
            Color(#colorLiteral(red: 0.5182887248, green: 0.6359114107, blue: 0.6388193965, alpha: 1))
        )

    
    }  // end body
    
    
}



public struct TextStyle {
    
    // This type is opaque because it exposes NSAttributedString details and
    // requires unique keys. It can be extended by public static methods.

    // Properties are internal to be accessed by StyledText
    internal let key: NSAttributedString.Key
    internal let apply: (Text) -> Text

    public init(key: NSAttributedString.Key, apply: @escaping (Text) -> Text) {
        self.key = key
        self.apply = apply
    }

    
    static func foregroundColor(_ color: Color) -> Self {
        return TextStyle(
            key: .init("TextStyleForegroundColor"),
            apply: { $0.foregroundColor(color) }
        )
    }

    static func bold() -> Self {
        return TextStyle(
            key: .init("TextStyleBold"), apply: { $0.bold() }
        )
    }
    
}



struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        RootView()
            .environmentObject(GlobalEnv())
            .environment(\.colorScheme, .light)
    }
}
