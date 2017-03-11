//
//  Serialization.swift
//  Tetris Engine
//
//  Created by Martin Kiss on 17 Feb 2017.
//  https://github.com/Tricertops/TetrisEngine
//
//  The MIT License (MIT)
//  Copyright © 2017 Martin Kiss
//

import Foundation


protocol Serializable {
    associatedtype Representation

    func serialize() -> Representation
    static func deserialize(_ representation: Representation) -> Self?
}


extension Serializable {
    public static func deserialize(_ representation: Any?) -> Self? {
        guard let representation = representation as? Self.Representation
            else { return nil }
        return Self.deserialize(representation)
    }
}

