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


final class Engine: Serializable {
    
    let width: Int
    let height: Int
    
    init(width: Int, height: Int, interval: TimeInterval) {
        assert(width >= 4)
        assert(height >= 10)
        self.width = width
        self.height = height
        initialInterval = interval
        
        board = Board(width: width, height: height + 5)
        
        currentBlock = Block(shape: .T)
        nextBlock = Block(shape: .T)
        
        state = .initialized
    }
    
    
    enum State {
        case initialized
        case running
        case paused
        case stopped
    }
    var state: State
    
    var timer: Timer?
    
    let initialInterval: TimeInterval
    
    var interval: TimeInterval {
        // Decrease asymptotically to zero.
        // Half of the initial time is around score 70, quarter around 210.
        let exponent = 1 / (Double(score) / 100 + 1)
        return initialInterval * pow(2, exponent) - 1
    }
    
    var score: Int = 0
    
    func scheduleTick(in time: TimeInterval? = nil) {
        cancelTick()
        
        let interval = time ?? self.interval
        let date = Date(timeIntervalSinceNow: interval)
        timer = Timer(fire: date, interval: interval, repeats: no) {
            [unowned self] _ in
            self.tick()
        }
        
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    func cancelTick() {
        timer?.invalidate()
        timer = nil
    }
    
    var dateStarted: Date = .distantFuture
    
    func start() {
        score = 0
        blockCount = 0
        board.clear()
        recentShapes = []
        currentBlock = generateNextBlock().placed(above: height, in: board)
        nextBlock = generateNextBlock()
        dateStarted = Date()
        
        callback?(.startGame)
        callback?(.newBlock)
        
        scheduleTick()
        state = .running
    }
    
    func pause() {
        cancelTick()
        state = .paused
    }
    
    func resume() {
        scheduleTick()
        state = .running
    }
    
    func stop() {
        cancelTick()
        state = .stopped
    }
    
    func tick() {
        assert(state == .running)
        cancelTick()
        
        if currentBlock.canFall(in: board) {
            currentBlock.fall()
            callback?(.fall)
            scheduleTick()
        }
        else if case .falling = currentBlock.cell {
            currentBlock.makeFrozen()
            blockCount += 1
            callback?(.freeze)
            
            let completed = board.findCompletedLines()
            if completed.count > 0 {
                board.remove(lines: completed)
                score += completed.count
                callback?(.completed(lines: completed))
            }
            
            if isGameOver {
                callback?(.gameOver)
                stop()
            }
            else {
                scheduleTick()
            }
        }
        else {
            currentBlock = nextBlock.placed(above: height, in: board)
            nextBlock = generateNextBlock()
            callback?(.newBlock)
            tick()
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
    
    var recentShapes: [Block.Shape] = []
    
    func generateNextBlock() -> Block {
        var shapes = Block.Shape.all
        for recent in recentShapes {
            let index = shapes.index(of: recent)!
            shapes.remove(at: index)
        }
        let shape = shapes.random()
        recentShapes.append(shape)
        let memory = 3
        let excess = recentShapes.count - memory
        if excess > 0 {
            recentShapes.removeFirst(excess)
        }
        return Block(shape: shape, orientation: Block.Orientation.all.random())
    }
    
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
    
    func drop(in time: TimeInterval = 0) {
        cancelTick()
        
        var distance = 0
        while currentBlock.isFalling && currentBlock.canFall(in: board) {
            currentBlock.fall()
            distance += 1
        }
        callback?(.drop(by: distance))
        scheduleTick(in: time)
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
    
    var isGameOver: Bool {
        return board.isFrozen(above: height)
    }
    
    var blockCount: Int = 0
    
    var shouldContinueAfterRestoration: Bool {
        return isGameOver.not && blockCount > 0
    }
    
    enum Event {
        typealias Degrees = Int
        case startGame
        case newBlock
        case fall
        case drop(by: Int)
        case moveLeft
        case moveRight
        case rotate(by: Degrees)
        case freeze
        case completed(lines: IndexSet)
        case gameOver
    }
    typealias Callback = (Event) -> Void
    var callback: Callback?
    
    
    typealias Representation = [String: Any]
    
    func serialize() -> Representation {
        var dict: Representation = [:]
        
        dict["width"] = width
        dict["height"] = height
        dict["initialInterval"] = initialInterval
        dict["score"] = score
        dict["blocks"] = blockCount
        
        dict["currentBlock"] = currentBlock.serialize()
        dict["nextBlock"] = nextBlock.serialize()
        dict["recentShapes"] = recentShapes.map { $0.serialize() }
        dict["board"] = board.serialize()
        
        dict["started"] = dateStarted
        dict["serialized"] = Date()
        
        return dict
    }
    
    static func deserialize(_ dict: Representation) -> Engine? {
        guard let width = dict["width"] as? Int else { return nil }
        guard let height = dict["height"] as? Int else { return nil }
        guard let interval = dict["initialInterval"] as? TimeInterval else { return nil }
        
        let engine = Engine(width: width, height: height, interval: interval)
        
        guard let score = dict["score"] as? Int else { return nil }
        engine.score = score
        
        guard let blocks = dict["blocks"] as? Int else { return nil }
        engine.blockCount = blocks
        
        guard let currentBlock = Block.deserialize(dict["currentBlock"]) else { return nil }
        engine.currentBlock = currentBlock
        
        guard let nextBlock = Block.deserialize(dict["nextBlock"]) else { return nil }
        engine.nextBlock = nextBlock
        
        guard let recentShapesStrings = dict["recentShapes"] as? [String] else { return nil }
        var recentShapes: [Block.Shape] = []
        for s in recentShapesStrings {
            guard let shape = Block.Shape.deserialize(s) else { return nil }
            recentShapes.append(shape)
        }
        engine.recentShapes = recentShapes
        
        guard let board = Board.deserialize(dict["board"]) else { return nil }
        engine.board = board
        
        guard let dateStarted = dict["started"] as? Date else { return nil }
        engine.dateStarted = dateStarted
        
        return engine
    }
    
}


