//
//  RGBA32.swift
//  Mandelbrot
//
//  Created by Robert Ryan on 5/13/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//

import Foundation
import CoreGraphics

/// Color in a pixel buffer.
///
/// This is a 8 bit per channel RGBA representation of a color.

struct RGBA32: Equatable {
    private var color: UInt32

    var red: UInt8 {
        return UInt8((color >> 24) & 255)
    }

    var green: UInt8 {
        return UInt8((color >> 16) & 255)
    }

    var blue: UInt8 {
        return UInt8((color >> 8) & 255)
    }

    var alpha: UInt8 {
        return UInt8((color >> 0) & 255)
    }

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        color = (UInt32(red) << 24) | (UInt32(green) << 16) | (UInt32(blue) << 8) | (UInt32(alpha) << 0)
    }

    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue

//    static func ==(lhs: RGBA32, rhs: RGBA32) -> Bool {
//        return lhs.color == rhs.color
//    }

    static let blackColor = RGBA32(red: 0, green: 0, blue: 0, alpha: 255)
}
