//
//  oscillator.swift
//  SleepNoise
//
//  Created by Max Buchholz on 4/8/24.
//

import Foundation
import AudioUnit
import AVFoundation
class Oscillator: NSObject {
    private var phY = 0.0
    private var f0 = 440.0
    private var sampleRate : Double = 44100.0
    public func fillWithWhiteNoise(mBuffers : AudioBuffer, v : Double, count: Int){
        let sz = Int(mBuffers.mDataByteSize)
        var wave = Array(repeating: 0.0, count: count)
        let bufferPointer = UnsafeMutableRawPointer(mBuffers.mData)
        if var bptr = bufferPointer {
            for i in 0..<(count) {
                wave[i] = Double.random(in: -1.0..<1.0)
            }
            print(count)
            for i in 0..<(count){
                let x : Int16 = Int16(wave[i] * v)
                if (i < (sz / 2)) {
                    bptr.assumingMemoryBound(to: Int16.self).pointee = x
                    bptr += 2   // increment by 2 bytes for next Int16 item
                    bptr.assumingMemoryBound(to: Int16.self).pointee = x
                    bptr += 2   // stereo, so fill both Left & Right channels
                }
            }
        }
    }
}

