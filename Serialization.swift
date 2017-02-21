//
//  Serialization.swift
//  Tetris
//
//  Created by Martin Kiss on 17 Feb 2017.
//  Copyright © 2017 Tricertops. All rights reserved.
//

import Foundation


protocol Serializable {
    associatedtype Representation

    func serialize() -> Representation
    static func deserialize(_ representation: Representation) -> Self?
}


extension Serializable {
    static func deserialize(_ representation: Any?) -> Self? {
        guard let representation = representation as? Self.Representation
            else { return nil }
        return Self.deserialize(representation)
    }
}

