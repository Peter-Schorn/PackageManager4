//
//  StatusMessages.swift
//  PackageManager
//
//  Created by Peter Schorn on 5/31/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation
import SwiftUI


@discardableResult
func pushStatusMessage(_ msg: String, isLoading: Bool) -> UUID {
    // let msg = (msg: msg, isLoading: isLoading, id: UUID())
    // typeAlias StatusMessage = (msg: String, isLoading: Bool, id: UUID)
    let msg = (message: msg, isLoading: isLoading, id: UUID())

    DispatchQueue.main.async {
        print("appending message to globalEnv:", msg.message)
        globalEnv.statusMessages.append(msg)
        // statusMessages.append(msg)
    }
    
    return msg.id
}


func updateStatusMessage(id: UUID, isLoading: Bool) {
    
    DispatchQueue.main.async {
        if let indx = globalEnv.statusMessages.firstIndex(
            where: { $0.id == id }
        ) {
            
            globalEnv.statusMessages[indx].isLoading = isLoading
        }
    }
    
}


func removeStatusMsg(_ id: UUID) {
    print("rootView: called remove status msg")
    
    DispatchQueue.main.async {
        globalEnv.statusMessages.removeAll { msg in
            msg.id == id
        }
    }
}

func removeAllStatusMsgs() {
    DispatchQueue.main.async {
        globalEnv.statusMessages.removeAll()
    }
}
