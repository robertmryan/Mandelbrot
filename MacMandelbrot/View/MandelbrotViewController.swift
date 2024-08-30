//
//  ViewController.swift
//  Mandelbrot
//
//  Created by Robert Ryan on 5/13/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//

import Cocoa
import os.log

class MandelbrotViewController: NSViewController {
    let poi = OSSignposter(subsystem: Bundle.main.bundleIdentifier!, category: .pointsOfInterest)

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var calculateMultiThreadButton: NSButton!
    @IBOutlet weak var calculateSingleThreadButton: NSButton!
    var buttons: [NSButton]!

    override func viewDidLoad() {
        super.viewDidLoad()
        buttons = [calculateMultiThreadButton, calculateSingleThreadButton]
    }

    @IBAction func didTapMultithreadButton(_ sender: Any) {
        buttons.forEach { $0.isEnabled = false }

        calculate(multithreaded: true) { _ in
            self.buttons.forEach { $0.isEnabled = true }
        }
    }

    @IBAction func didTapSingleThreadButton(_ sender: Any) {
        buttons.forEach { $0.isEnabled = false }
        calculate(multithreaded: false) { _ in
            self.buttons.forEach { $0.isEnabled = true }
        }
    }
}

private extension MandelbrotViewController {
    func calculate(multithreaded: Bool, completion: @Sendable @MainActor @escaping (Duration) -> Void) {
        let scale: CGFloat = NSScreen.main!.backingScaleFactor
        let size = imageView.bounds.size
        imageView.image = nil

        let start = ContinuousClock.now

        let realMinimum = -2.1
        let realMaximum = 0.6
        let imaginaryRange = (realMaximum - realMinimum) * Double(view.bounds.height / view.bounds.width)
        mandelbrot(
            multithreaded: multithreaded,
                   size: size,
                   scale: scale,
                   upperLeft: Complex(real: realMinimum, imaginary: imaginaryRange / 2),
            lowerRight: Complex(real: realMaximum, imaginary: -imaginaryRange / 2)
        ) { image in
                    self.imageView.image = image
            let elapsed = start.duration(to: .now)
            self.alert("Completed in \(elapsed).")
                    completion(elapsed)
        }
    }

}

private extension MandelbrotViewController {

    func alert(_ text: String) {
        let alert = NSAlert()
        alert.messageText = text
        alert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

    /// Calculate all Mandelbrot values for image.
    ///
    /// - parameter size:        The size of the image (in points)
    /// - parameter scale:       The scale of the image (i.e. how many pixels per point). E.g. retina devices may have scale of `2`.
    /// - parameter upperLeft:   The `Complex` number representing the upper left corner of the image.
    /// - parameter lowerRight:  The `Complex` number representing the lower right corner of the image.
    /// - parameter completion:  Completion handler for returning the resulting image.

    private func mandelbrot(multithreaded: Bool, size: NSSize, scale: CGFloat, upperLeft: Complex, lowerRight: Complex, completion: @Sendable @MainActor @escaping (NSImage?) -> Void) {
        // create graphics context and grab the pixel buffer

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rows = Int(size.height * scale)
        let columns = Int(size.width * scale)
        let imageSize = CGSize(width: columns, height: rows)

        let context = CGContext(data: nil, width: columns, height: rows, bitsPerComponent: 8, bytesPerRow: columns * 4, space: colorSpace, bitmapInfo: RGBA32.bitmapInfo)!
        guard let pixelBuffer = context.data?.bindMemory(to: RGBA32.self, capacity: columns * rows) else {
            fatalError("Unable to bind memory")
        }

        // Keep track of progress, pixel by pixel (decoupling UI from calculation so UI doesn't get backlogged)

        var pixelsProcessed: UInt = 0
        let source = DispatchSource.makeUserDataAddSource(queue: .main)

        source.setEventHandler { [unowned self] in
            pixelsProcessed += source.data
            self.progressIndicator.doubleValue = 100 * Double(pixelsProcessed) / (Double(rows * columns))
        }
        source.resume()

        // start calculation
        //
        // The `OSSignposter` signposts are in case you want to use "Points of Interest" tool in Instruments.

        let state = poi.beginInterval(#function, "\(multithreaded ? "Multi-threaded" : "Single-threaded")")

        let mandelbrot = Mandelbrot()

        let calculation = if multithreaded {
            mandelbrot.calculate
        } else {
            mandelbrot.calculateSingleThreaded
        }

        calculation(upperLeft, lowerRight, pixelBuffer, imageSize, source) {
            self.poi.endInterval(#function, state)

            guard let outputCGImage = context.makeImage() else {
                completion(nil)
                return
            }

            let image = NSImage(cgImage: outputCGImage, size: size)
            completion(image)
        }
    }
}
