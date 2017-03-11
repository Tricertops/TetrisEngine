//
//  Block.swift
//  Tetris Engine
//
//  Created by Martin Kiss on 17 Jan 2017.
//  https://github.com/Tricertops/TetrisEngine
//
//  The MIT License (MIT)
//  Copyright © 2017 Martin Kiss
//

import Foundation


public struct Block {
    
    public enum Shape: String {
        case O
        case I
        case S
        case Z
        case L
        case J
        case T
    }
    public let shape: Shape
    
    public enum Orientation: String {
        case north = "N"
        case east = "E"
        case west = "W"
        case south = "S"
    }
    public internal(set) var orientation: Orientation = .north
    
    public internal(set) var anchor: Position = Position(x: 0, y: 0)
    public internal(set) var relativePositions: [Position] = []
    
    public var absolutePositions: [Position] {
        return relativePositions.map {
            return Position(x: $0.x + anchor.x,
                            y: $0.y + anchor.y)
        }
    }
    
    public var rectangle: (x: Int, y: Int, width: Int, height: Int) {
        return calculateRectangle()
    }
    
    public init (shape: Shape = .T, orientation: Orientation = .north) {
        self.shape = shape
        self.orientation = orientation
        
        let indices = Block.matrixIndices(shape: shape, orientation: orientation)
        relativePositions = indices.map(Position.init(matrixIndex:))
    }
    
    var cell: Cell = .empty
}


extension Block {
    
    func calculateRectangle() -> (x: Int, y: Int, width: Int, height: Int) {
        var top = 0
        var left = 0
        var right = 0
        var bottom = 0
        for position in relativePositions {
            if top < position.y { top = position.y }
            if left > position.x { left = position.x }
            if right < position.x { right = position.x }
            if bottom > position.y { bottom = position.y }
        }
        return (x: left,
                y: bottom,
                width: right - left + 1,
                height: top - bottom + 1)
    }
    
    mutating func rotate(clockwise: Bool) {
        let newOrientation = (clockwise ? orientation.clockwise : orientation.counterClockwise)
        let indices = Block.matrixIndices(shape: shape, orientation: newOrientation)
        relativePositions = indices.map(Position.init(matrixIndex:))
    }
    
    func placed(above: Int, in board: Board) -> Block {
        var block = self
        let middle = Int(floor(Double(board.width) / 2))
        block.setInitialAnchor(above: above, middle: middle)
        block.makeFalling()
        return block
    }
    
    mutating func setInitialAnchor(above: Int, middle: Int) {
        var bottom = 0
        var left = 0
        var right = 0
        for position in relativePositions {
            if bottom > position.y { bottom = position.y }
            if left > position.x { left = position.x }
            if right < position.x { right = position.x }
        }
        let width = right - left + 1
        var centering = 0
        if width == 2 && left == 0 { centering = -1 }
        if width == 4 { centering = -1 }
        
        anchor = Position(
            x: middle + centering,
            y: above - bottom)
        
    }
    
    func canFall(in board: Board) -> Bool {
        return isFalling && canBePlaced(in: board) { $0.below }
    }
    
    func canBePlaced(in board: Board, using: (Position) -> Position = {$0}) -> Bool {
        for position in absolutePositions {
            if board.cell(at: using(position)).isFree.not {
                return no
            }
        }
        return yes
    }
    
    mutating func fall() {
        anchor = anchor.below
    }
    
    mutating func makeFalling() {
        cell = .falling(shape: shape)
    }
    
    mutating func makeFrozen() {
        cell = .frozen(shape: shape)
    }
    
    var isFalling: Bool {
        switch cell {
        case .falling: return yes
        default: return no
        }
    }
    
    func canMoveLeft(in board: Board) -> Bool {
        return isFalling && canBePlaced(in: board) { $0.left }
    }
    
    mutating func moveLeft() {
        anchor = anchor.left
    }
    
    func canMoveRight(in board: Board) -> Bool {
        return isFalling && canBePlaced(in: board) { $0.right }
    }
    
    mutating func moveRight() {
        anchor = anchor.right
    }
    
    mutating func rotate(in board: Board) -> Bool {
        var rotated = self
        rotated.orientation = orientation.clockwise
        let indices = Block.matrixIndices(shape: rotated.shape, orientation: rotated.orientation)
        rotated.relativePositions = indices.map(Position.init(matrixIndex:))
        
        let canBeRotated = rotated.attemptToFit(in: board)
        if canBeRotated {
            self = rotated
        }
        return canBeRotated
    }
    
    mutating func attemptToFit(in board: Board) -> Bool {
        if canBePlaced(in: board) {
            return yes
        }
        if canMoveLeft(in: board) {
            moveLeft()
            return yes
        }
        else if canMoveRight(in: board) {
            moveRight()
            return yes
        }
        if shape != .I {
            return no
        }
        // “I” shape is so long it makes sens to move by 2 cells.
        if orientation == .east || orientation == .west {
            moveLeft()
            if canMoveLeft(in: board) {
                moveLeft()
                return yes
            }
        }
        return no
    }
}

extension Block: Serializable {

    typealias Representation = [String: Any]
    
    func serialize() -> Representation {
        var dict: [String: Any] = [:]
        
        dict["shape"] = shape.serialize()
        dict["orientation"] = orientation.serialize()
        dict["anchor"] = anchor.serialize()
        dict["relativePositions"] = relativePositions.map { $0.serialize() }
        dict["cell"] = cell.serialize()
        
        return dict
    }
    static func deserialize(_ dict: Representation) -> Block? {
        guard let shape = Shape.deserialize(dict["shape"]) else { return nil }
        guard let orientation = Orientation.deserialize(dict["orientation"]) else { return nil }
        guard let anchor = Position.deserialize(dict["anchor"]) else { return nil }
        guard let cell = Cell.deserialize(dict["cell"]) else { return nil }
        guard let positionStrings = dict["relativePositions"] as? [[Int]] else { return nil }
        
        var block = Block(shape: shape, orientation: orientation)
        block.anchor = anchor
        block.cell = cell
        
        var positions: [Position] = []
        for s in positionStrings {
            guard let position = Position.deserialize(s) else { return nil }
            positions.append(position)
        }
        block.relativePositions = positions
        
        return block
    }
    
}


extension Block.Shape: Serializable {
    
    public static let all: [Block.Shape] = [.O, .I, .S, .Z, .L, .J, .T]
    
    typealias Representation = String
    
    func serialize() -> String {
        return rawValue
    }
    
    static func deserialize(_ string: String) -> Block.Shape? {
        return Block.Shape(rawValue: string.uppercased())
    }
}


extension Block.Orientation: Serializable {
    
    public static let all: [Block.Orientation] = [.north, .east, .west, .south]
    
    public var clockwise: Block.Orientation {
        switch self {
        case .north: return .east
        case .east:  return .south
        case .south: return .west
        case .west:  return .north
        }
    }
    
    public var counterClockwise: Block.Orientation {
        switch self {
        case .north: return .west
        case .west:  return .south
        case .south: return .east
        case .east:  return .north
        }
    }
    
    
    typealias Representation = String
    
    func serialize() -> String {
        return rawValue
    }
    static func deserialize(_ string: String) -> Block.Orientation? {
        return Block.Orientation(rawValue: string.uppercased())
    }
}


extension Position {
    init(matrixIndex: Int) {
        let x = matrixIndex / 10
        let y = matrixIndex % 10
        self.init(x: x - Block.relativeAnchor, y: y - Block.relativeAnchor)
    }
}


extension Block {
    // Matrix:
    //
    //    13
    // 02 12 22
    // 01 11 21 31
    // 00 10 20
    //
    // 11 is anchor point
    
    static let relativeAnchor = 1
    
    static func matrixIndices(shape: Shape, orientation: Orientation) -> [Int] {
        switch shape {
        case .O: return [10,(11),01,00,]
        case .I:
            switch orientation {
            case .north, .south: return [10,(11),12,13]
            case .west, .east:   return [01,(11),21,31]
            }
        case .S:
            switch orientation {
            case .north, .south: return [21,(11),10,00]
            case .west, .east:   return [10,(11),01,02]
            }
        case .Z:
            switch orientation {
            case .north, .south: return [01,(11),10,20]
            case .west, .east:   return [12,(11),01,00]
            }
        case .L:
            switch orientation {
            case .north: return [12,(11),10,20]
            case .west:  return [01,(11),21,22]
            case .south: return [10,(11),12,02]
            case .east:  return [21,(11),01,00]
            }
        case .J:
            switch orientation {
            case .north: return [12,(11),10,00]
            case .west:  return [01,(11),21,20]
            case .south: return [10,(11),12,22]
            case .east:  return [21,(11),01,02]
            }
        case .T:
            switch orientation {
            case .north: return [01,(11),21,10]
            case .west:  return [10,(11),12,21]
            case .south: return [01,(11),21,12]
            case .east:  return [10,(11),12,01]
            }
        }
    }
}

