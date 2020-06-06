//
//  Tooltip.swift
//  PackageManager
//
//  Created by Peter Schorn on 5/29/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation
import SwiftUI

struct Tooltip: NSViewRepresentable {
    
    let tooltip: String
    
    init(_ tooltip: String) {
        self.tooltip = tooltip
    }

    func makeNSView(context: NSViewRepresentableContext<Tooltip>) -> NSView {
        let view = NSView()
        view.toolTip = tooltip
        return view
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<Tooltip>) {
        nsView.toolTip = tooltip
    }
    
}
