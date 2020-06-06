//
//  projectUtilities.swift
//  PackageManager
//
//  Created by Peter Schorn on 5/28/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation
import SwiftUI
import AppKit


extension UserDefaults {
    
    func set(_ url: URL?, forKey key: UserSettingsKeys) {
        self.set(url, forKey: key.rawValue)
    }
    
}


/// Returns a string from the clipboard, or nil if none exists.
func pasteboardString() -> String? {
    
    return NSPasteboard.general.string(forType: .string)
    

}

