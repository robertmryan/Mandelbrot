//
//  Complex.swift
//  Mandelbrot
//
//  Created by Robert Ryan on 5/13/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//

import Foundation

/// Complex number

struct Complex {
    let real: Double
    let imaginary: Double

    init(real: Double, imaginary: Double) {
        self.real = real
        self.imaginary = imaginary
    }

    init(_ value: IntegerLiteralType) {
        self.init(real: Double(value), imaginary: 0)
    }

    init<T: BinaryFloatingPoint>(_ value: T) {
        self.init(real: Double(value), imaginary: 0)
    }
}

extension Complex {
    static func + (lhs: Complex, rhs: Complex) -> Complex {
        return Complex(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
    }

    static func * (lhs: Complex, rhs: Complex) -> Complex {
        return Complex(real: lhs.real * rhs.real - rhs.imaginary * lhs.imaginary, imaginary: lhs.imaginary * rhs.real + lhs.real * rhs.imaginary)
    }

    func pow2() -> Complex {
        return self * self
    }

    func abs() -> Double {
        return hypot(real, imaginary)
    }
}
