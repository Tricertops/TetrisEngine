//
//  Block.swift
//  Tetris
//
//  Created by Martin Kiss on 17 Jan 2017.
//  Copyright © 2017 Tricertops. All rights reserved.
//

import Foundation


struct Block {
    let shape: Shape
    var orientation: Orientation = .north
    
    var anchor: Position = Position(x: 0, y: 0)
    var relativePositions: [Position] = []
    var absolutePositions: [Position] {
        return relativePositions.map {
            return Position(x: $0.x + anchor.x,
                            y: $0.y + anchor.y)
        }
    }
    
    var cell: Cell = .empty
    
    init (shape: Shape = .T, orientation: Orientation = .north) {
        self.shape = shape
        self.orientation = orientation
        
        let indices = Block.matrixIndices(shape: shape, orientation: orientation)
        relativePositions = indices.map(Position.init(matrixIndex:))
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
        return canBePlaced(in: board) { $0.below }
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
    
    mutating func makeObstacle() {
        cell = .obstacle(shape: shape)
    }
    
    var isFalling: Bool {
        switch cell {
        case .falling: return yes
        default: return no
        }
    }
    
    func canMoveLeft(in board: Board) -> Bool {
        return canBePlaced(in: board) { $0.left }
    }
    
    mutating func moveLeft() {
        anchor = anchor.left
    }
    
    func canMoveRight(in board: Board) -> Bool {
        return canBePlaced(in: board) { $0.right }
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


extension Block {
    enum Shape {
        case O
        case I
        case S
        case Z
        case L
        case J
        case T
        
        static let all: [Shape] = [.O, .I, .S, .Z, .L, .J, .T]
    }
}


extension Block {
    enum Orientation {
        case north
        case east
        case west
        case south
        
        static let all: [Orientation] = [.north, .east, .west, .south]
        
        var clockwise: Orientation {
            switch self {
            case .north: return .east
            case .east:  return .south
            case .south: return .west
            case .west:  return .north
            }
        }
        
        var counterClockwise: Orientation {
            switch self {
            case .north: return .west
            case .west:  return .south
            case .south: return .east
            case .east:  return .north
            }
        }
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
            case .north, .south: return [01,(11),12,22]
            case .west, .east:   return [10,(11),01,02]
            }
        case .Z:
            switch orientation {
            case .north, .south: return [21,(11),12,02]
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
            case .west:  return [21,(11),01,02]
            case .south: return [10,(11),12,22]
            case .east:  return [01,(11),21,20]
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

