//
//  ViewController.swift
//  MobileMandelbrot
//
//  Created by Robert Ryan on 5/13/19.
//  Copyright © 2019 Robert Ryan. All rights reserved.
//

import UIKit

class MandelbrotViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var progressIndicator: UIProgressView!
    @IBOutlet weak var calculateMultiThreadButton: UIButton!
    @IBOutlet weak var calculateSingleThreadButton: UIButton!
    @IBOutlet var buttons: [UIButton]!

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
    func calculate(multithreaded: Bool, completion: @escaping (Double) -> Void) {
        let scale: CGFloat = UIScreen.main.scale
        let size = imageView.bounds.size
        imageView.image = nil

        let start = CACurrentMediaTime()

        let realMinimum = -2.1
        let realMaximum = 0.6
        let imaginaryRange = (realMaximum - realMinimum) * Double(view.bounds.height / view.bounds.width)
        mandelbrot(multithreaded: multithreaded,
                   size: size,
                   scale: scale,
                   upperLeft: Complex(real: realMinimum, imaginary: imaginaryRange / 2),
                   lowerRight: Complex(real: realMaximum, imaginary: -imaginaryRange / 2)) { image in
                    self.imageView.image = image
                    let elapsed = CACurrentMediaTime() - start
                    self.alert("Took \(elapsed) seconds")
                    completion(elapsed)
        }
    }
}

private extension MandelbrotViewController {

    func alert(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    /// Calculate all Mandelbrot values for image.
    ///
    /// - parameter size:        The size of the image (in points)
    /// - parameter scale:       The scale of the image (i.e. how many pixels per point). E.g. retina devices may have scale of `2`.
    /// - parameter upperLeft:   The `Complex` number representing the upper left corner of the image.
    /// - parameter lowerRight:  The `Complex` number representing the lower right corner of the image.
    /// - parameter completion:  Completion handler for returning the resulting image.

    func mandelbrot(multithreaded: Bool, size: CGSize, scale: CGFloat, upperLeft: Complex, lowerRight: Complex, completion: @escaping (UIImage?) -> Void) {
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
            self.progressIndicator.progress = Float(pixelsProcessed) / (Float(rows * columns))
        }
        source.resume()

        // start calculation
        //
        // The kdebug signposts are in case you want to use "Points of Interest" tool in Instruments.

        kdebug_signpost_start(0, 0, 0, 0, 0)

        let mandelbrot = Mandelbrot()

        var calculation = mandelbrot.calculateSingleThreaded
        if multithreaded {
            calculation = mandelbrot.calculate
        }

        calculation(upperLeft, lowerRight, pixelBuffer, imageSize, source) {
            kdebug_signpost_end(0, 0, 0, 0, 0)

            guard let outputCGImage = context.makeImage() else {
                completion(nil)
                return
            }

            let image = UIImage(cgImage: outputCGImage)
            completion(image)
        }
    }
}
