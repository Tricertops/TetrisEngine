//
//  Extensions.swift
//  Tetris Engine
//
//  Created by Martin Kiss on 17 Jan 2017.
//  https://github.com/Tricertops/TetrisEngine
//
//  The MIT License (MIT)
//  Copyright © 2017 Martin Kiss
//

import Foundation
import CoreGraphics

let yes = true
let no = false

typealias Degrees = CGFloat
typealias Radians = CGFloat

extension Bool {
    
    var not: Bool {
        return !self
    }
    
    static func random() -> Bool {
        return (Int.random(of: 2) == 0)
    }
}

extension Int {
    
    static func random(of: Int = .max) -> Int {
        let count = Swift.min(Swift.max(0, of), Int(Int32.max))
        return Int(arc4random_uniform(UInt32(count)))
    }
    
}

extension Array {
    
    func random() -> Element {
        return self[.random(of: count)]
    }
    
    var shuffled: [Element] {
        var copy = self
        copy.shuffle()
        return copy
    }
    
    mutating func shuffle() {
        for indexA in (0..<count).reversed() {
            let indexB = Int.random(of: indexA + 1)
            (self[indexA], self[indexB]) = (self[indexB], self[indexA])
        }
    }
}
