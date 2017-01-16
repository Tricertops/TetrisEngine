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
        
        self.rows = Array(repeating: Row(blocks: Array(repeating: .empty, count: width)), count: height)
        
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
    var interval: TimeInterval = 1
    
    func start() {
        self.currentPiece = generateRandomPiece()
        self.nextPiece = generateRandomPiece()
        
        let date = Date(timeIntervalSinceNow: self.interval)
        let timer = Timer(fire: date, interval: self.interval, repeats: yes) {
            [unowned self] _ in
            self.fallByTimer()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .commonModes)
        
        resume()
    }
    
    func pause() {
        self.timer?.fireDate = Date.distantFuture
        self.state = .paused
    }
    
    func resume() {
        
        
        self.state = .running
    }
    
    func stop() {
        self.timer?.invalidate()
        self.timer = nil
        self.state = .stopped
    }
    
    func fallByTimer() {
        print("fall by 1")
        self.callback?(.move)
    }
    
    var currentPiece: Piece
    var nextPiece: Piece
    
    func generateRandomPiece() -> Piece {
        return Piece(kind: Piece.Kind.random(), orientation: Piece.Orientation.random())
    }
    
    
    enum Block {
        case empty
        case filled(kind: Piece.Kind)
        case falling(kind: Piece.Kind)
        case shadow(kind: Piece.Kind)
        
        var isEmpty: Bool {
            switch self {
            case .empty: return yes
            default: return no
            }
        }
    }
    struct Row {
        var blocks: [Block]
    }
    var rows: [Row]
    func blockAt(x: Int, y: Int) -> Block {
        let filled = arc4random_uniform(2) == 0
        return (filled ? .filled(kind: .O) : .empty)
    }
    
    enum Step {
        case new
        case move
        case rotate
        case clear(lines: Range<Int>)
    }
    typealias Callback = (Step) -> Void
    var callback: Callback?
    
    var score: Int = 0
    
}


struct Piece {
    let kind: Kind
    var orientation: Orientation
}


extension Piece {
    enum Kind: String {
        case O
        case I
        case S
        case Z
        case L
        case J
        case T
        
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

