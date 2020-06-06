//
//  Images.swift
//  PackageManager test
//
//  Created by Peter Schorn on 6/5/20.
//  Copyright © 2020 Peter Schorn. All rights reserved.
//

import Foundation

import SwiftUI

enum ImageAssets: String {
    
    case checkMark
}

extension Image {
    
    init(_ image: ImageAssets) {
        self.init(image.rawValue)
    }
}
