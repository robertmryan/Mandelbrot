//
//  Mandelbrot.swift
//  Mandelbrot
//
//  Created by Robert Ryan on 5/13/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//
// swiftlint:disable identifier_name

@preconcurrency import Foundation
import CoreGraphics

final class Mandelbrot: Sendable {

    let maxIterations = 10_000
    let threshold = 2.0

    /// Calculate Mandelbrot set.
    ///
    /// - Parameters:
    ///   - upperLeft: The `Complex` value representing the upper left corner of the result.
    ///   - lowerRight: The `Complex` value representing the lower right corner of the result.
    ///   - pixelBuffer: The pixel buffer to be filled with the results.
    ///   - size: The `CGSize` representing the size of the pixel buffer. Note, `width` and `height` must be integer values.
    ///   - dispatchSource: The `DispatchSourceUserDataAdd` updated every time a pixel is calculated.
    ///   - completion: A block that is called when the calculation is done.

    func calculate(
        _ upperLeft: Complex,
        _ lowerRight: Complex,
        _ pixelBuffer: UnsafeMutablePointer<RGBA32>,
        _ size: CGSize,
        _ dispatchSource: DispatchSourceUserDataAdd? = nil,
        completion: @Sendable @MainActor @escaping () -> Void
    ) {
        let rows = Int(size.height)
        let columns = Int(size.width)
        let pixels = rows * columns

        nonisolated(unsafe) let pixelBuffer = pixelBuffer

        DispatchQueue.global(qos: .utility).async {
            DispatchQueue.chunkedConcurrentPerform(
                iterations: pixels,
                chunks: ProcessInfo.processInfo.activeProcessorCount * 8
            ) { range in
                for index in range {
                    let (row, column) = index.quotientAndRemainder(dividingBy: columns)
                let imaginary = self.imaginary(for: row, of: rows, between: upperLeft, and: lowerRight)
                    let real = self.real(for: column, of: columns, between: upperLeft, and: lowerRight)
                    let complex = Complex(real: real, imaginary: imaginary)
                    let value = self.value(for: complex)
                    pixelBuffer[row * columns + column] = self.color(for: value)
                    dispatchSource?.add(data: 1)
                }
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }

    /// Calculate Mandelbrot set (using one thread only).
    ///
    /// - Parameters:
    ///   - upperLeft: The `Complex` value representing the upper left corner of the result.
    ///   - lowerRight: The `Complex` value representing the lower right corner of the result.
    ///   - pixelBuffer: The pixel buffer to be filled with the results.
    ///   - size: The `CGSize` representing the size of the pixel buffer. Note, `width` and `height` must be integer values.
    ///   - dispatchSource: The `DispatchSourceUserDataAdd` updated every time a pixel is calculated.
    ///   - completion: A block that is called when the calculation is done.

    func calculateSingleThreaded(
        _ upperLeft: Complex,
        _ lowerRight: Complex,
        _ pixelBuffer: UnsafeMutablePointer<RGBA32>,
        _ size: CGSize,
        _ dispatchSource: DispatchSourceUserDataAdd? = nil,
        completion: @Sendable @MainActor @escaping () -> Void
    ) {
        let rows = Int(size.height)
        let columns = Int(size.width)
        nonisolated(unsafe) let pixelBuffer = pixelBuffer

        DispatchQueue.global(qos: .utility).async {
            for row in 0..<rows {
                let imaginary = self.imaginary(for: row, of: rows, between: upperLeft, and: lowerRight)
                for column in 0 ..< columns {
                    let real = self.real(for: column, of: columns, between: upperLeft, and: lowerRight)
                    let complex = Complex(real: real, imaginary: imaginary)
                    let value = self.value(for: complex)
                    pixelBuffer[row * columns + column] = self.color(for: value)
                    dispatchSource?.add(data: 1)
                }
            }

            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

private extension Mandelbrot {
    /// Calculate Mandelbrot value.
    ///
    /// - parameter c: Initial `Complex` value.
    ///
    /// - returns: The number of iterations for `z = z^2 + c` to escape `threshold`.

    nonisolated func value(for complexValue: Complex) -> Int? {
        var z = Complex(0)
        var iteration = 0

        repeat {
            z = z.pow2() + complexValue
            iteration += 1
        } while z.abs() <= threshold && iteration < maxIterations

        return iteration >= maxIterations ? nil : iteration
    }

    /// Determine color based upon Mandelbrot value.
    ///
    /// You can use whatever algorithm you want for coloring the pixel.
    ///
    /// - parameter mandelbrotValue: The number of iterations required to escape threshold in Mandelbrot calculation.
    ///
    /// - returns: A `RGBA32` color.

    nonisolated func color(for mandelbrotValue: Int?) -> RGBA32 {
        guard let mandelbrotValue = mandelbrotValue else {
            return RGBA32.blackColor
        }

        let integerValue = UInt8(min(255.0, pow(Double(min(255, mandelbrotValue-1)), 1.7)))
        return RGBA32(red: integerValue, green: integerValue, blue: 255, alpha: 255)
    }

    /// Get imaginary component.
    ///
    /// - parameter row:        Zero-based row number.
    /// - parameter rows:       Total number of rows in which the `row` falls.
    /// - parameter upperLeft:  A `Complex` number representing the upper left of the image.
    /// - parameter lowerRight: A `Complex` number representing the lower right of the image.
    ///
    /// - returns: A `Double` of the imaginary value corresponding this this `row`.

    func imaginary(for row: Int, of rows: Int, between upperLeft: Complex, and lowerRight: Complex) -> Double {
        let rowPercent = Double(row) / Double(rows)
        return upperLeft.imaginary + (lowerRight.imaginary - upperLeft.imaginary) * rowPercent
    }

    /// Get real component.
    ///
    /// - parameter column:     Zero-based column number.
    /// - parameter columns:    Total number of columns in which the `column` fall.
    /// - parameter upperLeft:  A `Complex` number representing the upper left of the image.
    /// - parameter lowerRight: A `Complex` number representing the lower right of the image.
    ///
    /// - returns: A `Complex` of the value corresponding to this column (and the previously
    ///            calculated imaginary component.

    func real(for column: Int, of columns: Int, between upperLeft: Complex, and lowerRight: Complex) -> Double {
        let columnPercent = Double(column) / Double(columns)
        return upperLeft.real + (lowerRight.real - upperLeft.real) * columnPercent
    }
}
