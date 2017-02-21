//
//  Board.swift
//  Tetris
//
//  Created by Martin Kiss on 17 Jan 2017.
//  Copyright © 2017 Tricertops. All rights reserved.
//

import Foundation


struct Position: Serializable {
    var x: Int
    var y: Int
    
    var above: Position {
        return Position(x: x, y: y + 1)
    }
    var below: Position {
        return Position(x: x, y: y - 1)
    }
    var left: Position {
        return Position(x: x - 1, y: y)
    }
    var right: Position {
        return Position(x: x + 1, y: y)
    }
    
    typealias Representation = [Int]
    func serialize() -> Representation {
        return [x, y]
    }
    static func deserialize(_ array: Representation) -> Position? {
        guard array.count == 2 else { return nil }
        
        return Position(x: array[0], y: array[1])
    }
}


final class Board: Serializable {
    let width: Int
    let height: Int
    var cells: [Cell] = []
    
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        cells = []
        clear()
    }
    
    func index(for position: Position) -> Int {
        return position.y * width + position.x
    }
    
    func cell(at: Position) -> Cell {
        guard at.x >= 0 else { return .outer }
        guard at.y >= 0 else { return .outer }
        guard at.x < width  else { return .outer }
        guard at.y < height else { return .outer }
        
        return cells[index(for: at)]
    }
    
    func set(cell: Cell, at: Position) {
        if case .outer = cell { return }
        guard at.x >= 0 else { return }
        guard at.y >= 0 else { return }
        guard at.x < width  else { return }
        guard at.y < height else { return }
        
        cells[index(for: at)] = cell
    }
    
    func clear() {
        cells = Array(repeating: .empty, count: width * height)
    }
    
    func isFrozen(above: Int) -> Bool {
        for y in above..<height {
            for x in 0..<width {
                if cell(at: Position(x: x, y: y)).isFree.not {
                    return yes
                }
            }
        }
        return no
    }
    
    func print() {
        var lines: [String] = []
        for y in 0..<height {
            lines.insert("", at: 0)
            for x in 0..<width {
                let c = cell(at: Position(x: x, y: y))
                lines[0] += c.visualDescription
            }
        }
        Swift.print(lines.joined(separator: "\n"))
    }
    
    func findCompletedLines() -> IndexSet {
        var lines = IndexSet()
        for y in 0..<height {
            if isCompleted(line: y) {
                lines.insert(y)
            }
        }
        return lines
    }
    
    func isCompleted(line: Int) -> Bool {
        for x in 0..<width {
            if cell(at: Position(x: x, y: line)).isCompleted.not {
                return no
            }
        }
        return yes
    }
    
    func remove(lines: IndexSet) {
        for y in lines.reversed() {
            for x in (0..<width).reversed() {
                let position = Position(x: x, y: y)
                cells.remove(at: index(for: position))
                cells.append(.empty)
            }
        }
    }
    
    
    typealias Representation = [String: Any]
    
    func serialize() -> Representation {
        var dict: Representation = [:]
        
        dict["width"] = width
        dict["height"] = height
        dict["cells"] = cells.map { $0.serialize() }
        
        return dict
    }
    static func deserialize(_ dict: Representation) -> Board? {
        guard let width = dict["width"] as? Int else { return nil }
        guard let height = dict["height"] as? Int else { return nil }
        
        let board = Board(width: width, height: height)
        
        guard let cellsStrings = dict["cells"] as? [String] else { return nil }
        guard cellsStrings.count == width * height else { return nil }
        var cells: [Cell] = []
        for s in cellsStrings {
            guard let cell = Cell.deserialize(s) else { return nil }
            cells.append(cell)
        }
        board.cells = cells
        
        return board
    }
    
}


enum Cell: Serializable {
    case empty
    case frozen(shape: Block.Shape)
    case falling(shape: Block.Shape)
    case outer
    
    var isEmpty: Bool {
        switch self {
        case .empty: return yes
        default: return no
        }
    }
    
    var isFree: Bool {
        switch self {
        case .empty, .falling:
            return yes
        default:
            return no
        }
    }
    
    var isCompleted: Bool {
        switch self {
        case .frozen: return yes
        default: return no
        }
    }
    
    var visualDescription: String {
        switch self {
        case .empty: return "∙"
        case .frozen: return "█"
        case .falling: return "▓"
        case .outer: return "╳"
        }
    }
    
    
    typealias Representation = String
    
    func serialize() -> Representation {
        switch self {
        case .empty: return " "
        case .frozen(let shape): return shape.serialize().uppercased()
        case .falling(let shape): return shape.serialize().lowercased()
        case .outer: return "X"
        }
    }
    static func deserialize(_ string: Representation) -> Cell? {
        if string == " " {
            return .empty
        }
        if string == "X" {
            return .outer
        }
        if string == string.uppercased() {
            guard let shape = Block.Shape.deserialize(string) else { return nil }
            return .frozen(shape: shape)
        }
        if string == string.lowercased() {
            guard let shape = Block.Shape.deserialize(string) else { return nil }
            return .falling(shape: shape)
        }
        return nil
    }
}

