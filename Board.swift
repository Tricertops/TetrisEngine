//
//  Board.swift
//  Tetris
//
//  Created by Martin Kiss on 17 Jan 2017.
//  Copyright © 2017 Tricertops. All rights reserved.
//

import Foundation


struct Position {
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
}


class Board {
    let width: Int
    let height: Int
    var cells: [Cell] = []
    
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        cells = []
        clear()
    }
    
    
    func cell(at: Position) -> Cell {
        guard at.x >= 0 else { return .outer }
        guard at.y >= 0 else { return .outer }
        guard at.x < width  else { return .outer }
        guard at.y < height else { return .outer }
        
        let index = at.y * width + at.x
        return cells[index]
    }
    
    func set(cell: Cell, at: Position) {
        if case .outer = cell { return }
        guard at.x >= 0 else { return }
        guard at.y >= 0 else { return }
        guard at.x < width  else { return }
        guard at.y < height else { return }
        
        let index = at.y * width + at.x
        cells[index] = cell
    }
    
    func clear() {
        cells = Array(repeating: .empty, count: width * height)
    }
    
    func isObstacle(above: Int) -> Bool {
        for y in above..<height {
            for x in 0..<width {
                if cell(at: Position(x: x, y: y)).isNotFree {
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
    
}


enum Cell {
    case empty
    case obstacle(shape: Block.Shape)
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
    
    var isNotFree: Bool {
        return !isFree
    }
    
    var visualDescription: String {
        switch self {
        case .empty: return "∙"
        case .obstacle: return "█"
        case .falling: return "▓"
        case .outer: return "╳"
        }
    }
}

