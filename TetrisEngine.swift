//
//  TetrisEngine.swift
//  Tetris Engine
//
//  Created by Martin Kiss on 16 Jan 2017.
//  https://github.com/Tricertops/TetrisEngine
//
//  The MIT License (MIT)
//  Copyright © 2017 Martin Kiss
//

import Foundation


let yes = true
let no = false


class Engine {
    
    let width: Int
    let height: Int
    
    init(width: Int, height: Int) {
        assert(width >= 4)
        assert(height >= 10)
        self.width = width
        self.height = height
        
        self.board = Board(width: width, height: height + 5)
        
        self.currentPiece = Piece(kind: .T, orientation: .north)
        self.nextPiece = Piece(kind: .T, orientation: .north)
        
        self.state = .initialized
    }
    
    
    enum State {
        case initialized
        case running
        case paused
        case stopped
    }
    var state: State
    
    var timer: Timer?
    //TODO: Higher score -> shorter intervals.
    var interval: TimeInterval = 1
    
    func start() {
        self.currentPiece = generateRandomPiece()
        self.nextPiece = generateRandomPiece()
        
        self.board.clear()
        
        let date = Date(timeIntervalSinceNow: self.interval)
        let timer = Timer(fire: date, interval: self.interval, repeats: yes) {
            [unowned self] _ in
            self.timerTick()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .commonModes)
        
        self.callback?(.newPiece)
        resume()
    }
    
    func pause() {
        self.timer?.fireDate = Date.distantFuture
        self.state = .paused
    }
    
    func resume() {
        self.timer?.fireDate = Date(timeIntervalSinceNow: self.interval)
        self.state = .running
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
        self.state = .stopped
    }
    
    func timerTick() {
        if self.state != .running {
            return
        }
        fallByOneBlock()
        if self.state == .stopped {
            return
        }
        if isFalling {
            self.callback?(.fall(by: 1))
        }
        else {
            self.currentPiece = self.nextPiece
            self.nextPiece = self.generateRandomPiece()
            placeCurrentPieceAboveBoard()
            self.callback?(.newPiece)
        }
    }
    
    var currentPiece: Piece
    var nextPiece: Piece
    
    var isFalling: Bool = no
    
    typealias Coordinate = (x: Int, y: Int)
    var fallingAnchor: Coordinate = (0,0)
    var fallingCoordinates: [Coordinate] = []
    
    func placeCurrentPieceAboveBoard() {
        var coords = self.currentPiece.kind.defaultCoordinates
        coords = coords.map { rotateCoordinate($0, around: (0,0), to: self.currentPiece.orientation) }
        
        var left = 0
        var right = 0
        var bottom = 0
        for coordinate in coords {
            left = min(left, coordinate.x)
            right = max(right, coordinate.x)
            bottom = min(bottom, coordinate.y)
        }
        let correction = (abs(left) < abs(right) ? -1 : 0)
        let anchor = (x: self.width / 2 + correction,
                      y: self.height - bottom)
        
        self.fallingAnchor = anchor
        coords = coords.map { (x: $0.x + anchor.x, y: $0.y + anchor.y) }
        self.isFalling = yes
        updateFallingBlocks(coordinates: coords)
    }
    
    func fallByOneBlock() {
        if isTouchedDown {
            self.isFalling = no
            makeFalledBlockPermanent()
            self.fallingAnchor = (0,0)
            self.fallingCoordinates = []
        }
        else {
            let coords = self.fallingCoordinates.map { (x: $0.x, y: $0.y - 1) }
            updateFallingBlocks(coordinates: coords)
        }
    }
    
    func updateFallingBlocks(coordinates: [Coordinate]) {
        for coord in self.fallingCoordinates {
            self.board.setBlockAt(x: coord.x, y: coord.y, block: .empty)
        }
        self.fallingCoordinates = coordinates
        let kind = self.currentPiece.kind
        for coord in self.fallingCoordinates {
            self.board.setBlockAt(x: coord.x, y: coord.y, block: .falling(kind: kind))
        }
    }
    
    var isTouchedDown: Bool {
        for coord in self.fallingCoordinates {
            if (coord.y == 0) {
                return yes
            }
            let blockBelow = self.board.blockAt(x: coord.x, y: coord.y - 1)
            if case .filled = blockBelow {
                return yes
            }
        }
        return no
    }
    
    func makeFalledBlockPermanent() {
        let kind = self.currentPiece.kind
        for coord in self.fallingCoordinates {
            self.board.setBlockAt(x: coord.x, y: coord.y, block: .filled(kind: kind))
        }
        checkForGameOver()
    }
    
    func checkForGameOver() {
        for y in self.height..<self.board.height {
            for x in 0..<self.width {
                let block = self.board.blockAt(x: x, y: y)
                if case .filled = block {
                    stop()
                    self.callback?(.gameOver)
                }
            }
        }
    }
    
    func rotateCoordinate(_ coord: Coordinate, around: Coordinate, to orientation: Piece.Orientation) -> Coordinate {
        switch orientation {
        case .north: return ( coord.x,  coord.y)
        case .south: return (-coord.x, -coord.y)
        case .west:  return (-coord.y,  coord.x)
        case .east:  return ( coord.y, -coord.x)
        }
    }
    
    func generateRandomPiece() -> Piece {
        return Piece(kind: Piece.Kind.random(), orientation: Piece.Orientation.random())
    }
    
    func moveLeft() {
        if !self.canMoveLeft {
            return
        }
        
        let coords = self.fallingCoordinates.map { (x: $0.x - 1, y: $0.y) }
        updateFallingBlocks(coordinates: coords)
        
        self.callback?(.userMove(offset: -1))
    }
    
    var canMoveLeft: Bool {
        for coord in self.fallingCoordinates {
            if coord.x == 0 {
                return no
            }
            let leftBlock = self.board.blockAt(x: coord.x - 1, y: coord.y)
            if case .filled = leftBlock {
                return no
            }
        }
        return yes
    }
    
    func moveRight() {
        if !self.canMoveRight {
            return
        }
        
        let coords = self.fallingCoordinates.map { (x: $0.x + 1, y: $0.y) }
        updateFallingBlocks(coordinates: coords)
        
        self.callback?(.userMove(offset: +1))
    }
    
    var canMoveRight: Bool {
        for coord in self.fallingCoordinates {
            if coord.x + 1 == self.width {
                return no
            }
            let rightBlock = self.board.blockAt(x: coord.x + 1, y: coord.y)
            if case .filled = rightBlock {
                return no
            }
        }
        return yes
    }
    
    
    var board: Board
    func blockAt(x: Int, y: Int) -> Board.Block {
        return self.board.blockAt(x: x, y: y)
    }
    
    enum Event {
        typealias Degrees = Int
        case newPiece
        case fall(by: Int)
        case userMove(offset: Int)
        case userRotate(by: Degrees)
        case clearedLines(range: Range<Int>)
        case gameOver
    }
    typealias Callback = (Event) -> Void
    var callback: Callback?
    
    var score: Int = 0
    
}


struct Board {
    let width: Int
    let height: Int
    
    enum Block {
        case empty
        case filled(kind: Piece.Kind)
        case falling(kind: Piece.Kind)
        
        var isEmpty: Bool {
            switch self {
            case .empty: return yes
            default: return no
            }
        }
    }
    var blocks: [Block] = []
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.blocks = []
        self.clear()
    }
    
    mutating func clear() {
        self.blocks = Array(repeating: .empty, count: width * height)
    }
    
    func blockAt(x: Int, y: Int) -> Block {
        return blocks[y * width + x]
    }
    
    mutating func setBlockAt(x: Int, y: Int, block: Block) {
        blocks[y * width + x] = block
    }
    
    mutating func deleteRow(_ row: Int) {
        let from = row * width
        let to = from + width
        blocks.replaceSubrange(from..<to, with: [])
    }
}


struct Piece {
    let kind: Kind
    var orientation: Orientation
}


extension Piece {
    enum Kind: String {
        
        case O
        // MM
        // OM
        
        case I
        // M
        // M
        // O
        // M
        
        case S
        //  MM
        // MO
        
        case Z
        // MM
        //  OM
        
        case L
        // M
        // O
        // MM
        
        case J
        //  M
        //  O
        // MM
        
        case T
        // MOM
        //  M
        
        static let all: [Kind] = [.O, .I, .S, .Z, .L, .J, .T]
        
        static func random() -> Kind {
            let index = Int(arc4random_uniform(UInt32(all.count)))
            return all[index]
        }
    }
}


extension Piece {
    enum Orientation {
        case north
        case east
        case west
        case south
        
        static let all: [Orientation] = [.north, .east, .west, .south]
        
        static func random() -> Orientation {
            let index = Int(arc4random_uniform(UInt32(all.count)))
            return all[index]
        }
    }
}


extension Piece.Kind {
    var defaultCoordinates: [Engine.Coordinate] {
        switch self {
        case .O: return [(0,0),(0,1),(1,0),(1,1)]
        case .I: return [(0,-1),(0,0),(0,1),(0,2)]
        case .S: return [(-1,0),(0,0),(0,1),(1,1)]
        case .Z: return [(-1,1),(0,1),(0,0),(1,0)]
        case .L: return [(0,-1),(1,-1),(0,0),(0,1)]
        case .J: return [(-1,-1),(0,-1),(0,0),(0,1)]
        case .T: return [(-1,0),(0,0),(1,0),(0,-1)]
        }
    }
}

