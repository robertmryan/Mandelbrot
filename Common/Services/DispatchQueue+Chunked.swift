//
//  DispatchQueue+Chunked.swift
//
//  Created by Robert Ryan on 8/30/24.
//  Copyright © 2024 Robert Ryan. All rights reserved.
//

import Foundation

extension DispatchQueue {
    /// Chunked concurrentPerform
    ///
    /// - Parameters:
    ///   - iterations: How many total iterations.
    ///   - chunks: How many chunks into which these iterations will be divided. This is optional and will default to
    ///      `activeProcessorCount`. If the work is largely uniform, you can safely omit this parameter and the
    ///      work will evenly distributed amongst the CPU cores.
    ///
    ///      If different chunks are likely to take significantly different amounts of time,
    ///      you may want to increase this value above the processor count to avoid blocking the whole process
    ///      for slowest chunk and afford the opportunity for threads processing faster chunks to handle more than one.
    ///
    ///      But, be careful to not increase this value too high, as each dispatched chunk entails a modest amount of overhead.
    ///      You may want to empirically test different chunk sizes (vs the default value) for your particular use-case.
    ///   - chunk: Closure to be called for each chunk.

    static func chunkedConcurrentPerform(
        iterations: Int,
        chunks: Int? = nil,
        chunk: @Sendable (Range<Int>) -> Void
    ) {
        let chunks = min(iterations, chunks ?? ProcessInfo.processInfo.activeProcessorCount)
        let (baseChunkSize, remainder) = iterations.quotientAndRemainder(dividingBy: chunks)

        concurrentPerform(iterations: chunks) { chunkIndex in
            let start = chunkIndex * baseChunkSize + min(chunkIndex, remainder)
            let end = start + baseChunkSize + (chunkIndex < remainder ? 1 : 0)
            chunk(start ..< end)
        }
    }
}
