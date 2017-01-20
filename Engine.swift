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


class Engine {
    
    let width: Int
    let height: Int
    
    init(width: Int, height: Int) {
        assert(width >= 4)
        assert(height >= 10)
        self.width = width
        self.height = height
        
        self.board = Board(width: width, height: height + 5)
        
        self.currentBlock = Block(shape: .T)
        self.nextBlock = Block(shape: .T)
        
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
        self.board.clear()
        
        let date = Date(timeIntervalSinceNow: self.interval)
        let timer = Timer(fire: date, interval: self.interval, repeats: yes) {
            [unowned self] _ in
            self.timerTick()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .commonModes)
        
        self.callback?(.startGame)
        
        currentBlock = Block.random().placed(above: height, in: board)
        nextBlock = Block.random()
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
        if currentBlock.canFall(in: board) {
            currentBlock.fall()
            self.callback?(.fall)
        }
        else if case .falling = currentBlock.cell {
            currentBlock.makeObstacle()
            
            //TODO: Detect completed lines
            if board.isObstacle(above: height) {
                callback?(.gameOver)
                stop()
            }
        }
        else {
            currentBlock = nextBlock.placed(above: height, in: board)
            nextBlock = Block.random()
            self.callback?(.newPiece)
        }
    }
    
    var currentBlock: Block {
        willSet {
            let oldBlock = currentBlock
            if oldBlock.isFalling {
                for position in oldBlock.absolutePositions {
                    board.set(cell: .empty, at: position)
                }
            }
        }
        didSet {
            let newBlock = currentBlock
            let cell: Cell = newBlock.cell
            
            for position in newBlock.absolutePositions {
                board.set(cell: cell, at: position)
            }
        }
    }
    var nextBlock: Block
    
    func moveLeft() {
        if currentBlock.canMoveLeft(in: board) {
            currentBlock.moveLeft()
            callback?(.moveLeft)
        }
    }
    
    func moveRight() {
        if currentBlock.canMoveRight(in: board) {
            currentBlock.moveRight()
            callback?(.moveRight)
        }
    }
    
    func drop() {
        var distance = 0
        while currentBlock.isFalling && currentBlock.canFall(in: board) {
            currentBlock.fall()
            distance += 1
        }
        callback?(.drop(by: distance))
    }
    
    func rotate() {
        if currentBlock.rotate(in: board) {
            callback?(.rotate(by: 90))
        }
    }
    
    var board: Board
    func cellAt(x: Int, y: Int) -> Cell {
        return board.cell(at: Position(x: x, y: y))
    }
    
    enum Event {
        typealias Degrees = Int
        case startGame
        case newPiece
        case fall
        case drop(by: Int)
        case moveLeft
        case moveRight
        case rotate(by: Degrees)
        case cleared(range: Range<Int>)
        case gameOver
    }
    typealias Callback = (Event) -> Void
    var callback: Callback?
    
    var score: Int = 0
    
}





