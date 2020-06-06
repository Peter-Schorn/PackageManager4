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
    
    func undo(_ redoAction: @escaping () -> Void) {
        
        self.redoStack.append(redoAction)
        
        if !self.undoStack.isEmpty {
            self.undoStack.removeLast()()
        }
    }
    
    func redo(_ undoAction: @escaping () -> Void) {
        
        self.undoStack.append(undoAction)
        
        if !self.redoStack.isEmpty {
            self.redoStack.removeLast()()
        }
    }
    
}
