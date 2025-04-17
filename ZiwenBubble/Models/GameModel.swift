//
//  GameModel.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.17.
//

import Foundation

import Foundation
import SwiftUI

// Bubble Model
struct Bubble: Identifiable, Equatable {
	let id = UUID()
	var position: CGPoint
	var color: BubbleColor
	var size: CGFloat
	var isPopped: Bool = false
	var velocity: CGVector = .zero
	
	// Returns the bubble's point value
	var points: Int {
		return color.points
	}
	
	// Check if this bubble overlaps with another
	func overlaps(with other: Bubble, inBounds bounds: CGRect) -> Bool {
		// Calculate the minimum distance to avoid overlap
		let minDistance = (size + other.size) / 2
		
		// Calculate actual distance
		let dx = position.x - other.position.x
		let dy = position.y - other.position.y
		let distance = sqrt(dx*dx + dy*dy)
		
		// Check if the bubbles overlap
		return distance < minDistance
	}
	
	// Check if the bubble is within the screen bounds
	func isInBounds(_ bounds: CGRect) -> Bool {
		let radius = size / 2
		return position.x >= radius &&
			   position.x <= bounds.width - radius &&
			   position.y >= radius &&
			   position.y <= bounds.height - radius
	}
	
	// Move the bubble according to its velocity
	mutating func move(bounds: CGRect, timeElapsed: Double) {
		position.x += CGFloat(velocity.dx * timeElapsed)
		position.y += CGFloat(velocity.dy * timeElapsed)
	}
}

// Bubble Color
enum BubbleColor: CaseIterable {
	case red
	case pink
	case green
	case blue
	case black
	
	// Points for each color
	var points: Int {
		switch self {
		case .red: return 1
		case .pink: return 2
		case .green: return 5
		case .blue: return 8
		case .black: return 10
		}
	}
	
	// Probability for each color
	var probability: Double {
		switch self {
		case .red: return 0.40
		case .pink: return 0.30
		case .green: return 0.15
		case .blue: return 0.10
		case .black: return 0.05
		}
	}
	
	// Bubble Color
	var uiColor: Color {
		switch self {
		case .red: return .red
		case .pink: return .pink
		case .green: return .green
		case .blue: return .blue
		case .black: return .black
		}
	}
	
	// Generate a random color based on probability
	static func random() -> BubbleColor {
		let rand = Double.random(in: 0..<1)
		var cumulativeProbability = 0.0
		
		for color in BubbleColor.allCases {
			cumulativeProbability += color.probability
			if rand < cumulativeProbability {
				return color
			}
		}
		
		// Default fallback
		return .red
	}
}

// Game Score Model
struct GameScore: Identifiable, Codable, Comparable {
	var id = UUID()
	let playerName: String
	let score: Int
	let date: Date
	
	static func < (lhs: GameScore, rhs: GameScore) -> Bool {
		return lhs.score > rhs.score // Higher scores come first
	}
}

// Game State
enum GameState {
	case setup     // Initial state, collecting player info
	case starting  // Countdown to game start
	case playing   // Game in progress
	case paused    // Game paused
	case finished  // Game over
}
