//
//  Boolean.swift
//  Tetris
//
//  Created by Martin Kiss on 17 Jan 2017.
//  Copyright © 2017 Tricertops. All rights reserved.
//
import Foundation

let yes = true
let no = false

extension Bool {
    
    var not: Bool {
        return !self
    }
    
    static func random() -> Bool {
        return (arc4random_uniform(2) == 0)
    }
}
