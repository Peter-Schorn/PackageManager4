//
//  File.swift
//  PlaygroundPackageManager
//
//  Created by Peter Schorn on 4/25/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation
import SwiftUI

class UndoRedoManager {
    
    
    private(set) var undoStack: [() -> Void] = []
    private(set) var redoStack: [() -> Void] = []
        
    func addUndoAction(_ action: @escaping () -> Void) {
        self.undoStack.append(action)
    }
    
    /// Performs the last registered undo action
    /// and accepts a redo action
    func undo(_ redoAction: @escaping () -> Void) {
        print("undo")
        self.redoStack.append(redoAction)
        
        if !self.undoStack.isEmpty {
            self.undoStack.removeLast()()
        }
    }
    
    /// Performs the last registered redo action
    /// and accepts an undo action
    func redo(_ undoAction: @escaping () -> Void) {
        print("redo")
        self.undoStack.append(undoAction)
        
        if !self.redoStack.isEmpty {
            self.redoStack.removeLast()()
        }
    }
    
}
