//
//  GameViewModel.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.17.
//

import Foundation
import SwiftUI
import Combine

class GameViewModel: ObservableObject {

	@Published var bubbles: [Bubble] = []
	@Published var score: Int = 0
	@Published var timeRemaining: Int = 60
	@Published var gameState: GameState = .setup
	@Published var lastPoppedColor: BubbleColor? = nil
	@Published var comboCount: Int = 0
	@Published var highestScore: Int = 0
	@Published var countdownValue: Int = 3
	@Published var shouldShowHighScores: Bool = false
	@Published var currentScoreId: UUID?

	private var settings: SettingsModel
	private var timer: Timer?
	private var scoreTimer: Timer?
	private var bubbleRefreshTimer: Timer?
	private var movementTimer: Timer?
	private var comboMultiplier: Double = 1.5
	private var lastPoppedTime: Date?
	private var gameStartTime: Date?
	private var animatingBubbles: [UUID: Bool] = [:]
	private var difficultyFactor: Double = 1.0
	private let bubbleSize: CGFloat = 60
	private var maxBubblesCount: Int
	private let scoreManager = ScoreManager()

	private var screenBounds: CGRect = UIScreen.main.bounds
	
	// Initialization
	init(settings: SettingsModel) {
		self.settings = settings
		self.maxBubblesCount = settings.maxBubbles
		self.timeRemaining = settings.gameTime
		self.highestScore = scoreManager.getHighestScore()
	}
	
	// Game Control Methods
	func startGame() {
		// Reset game state
		resetGame()
		shouldShowHighScores = false
		
		// Show countdown animation
		gameState = .starting
		countdownValue = 3
		
		// Start countdown timer
		Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
			guard let self = self else { timer.invalidate(); return }
			
			if self.countdownValue > 1 {
				self.countdownValue -= 1
			} else {
				timer.invalidate()
				self.actuallyStartGame()
			}
		}
	}
	
	private func actuallyStartGame() {
		// Set game state to playing
		gameState = .playing
		gameStartTime = Date()
		
		// Reset score and time
		score = 0
		timeRemaining = settings.gameTime
		
		// Generate initial bubbles
		refreshBubbles()
		
		// Start game timer
		startTimers()
	}
	
	func pauseGame() {
		gameState = .paused
		stopTimers()
	}
	
	func resumeGame() {
		gameState = .playing
		startTimers()
	}
	
	func endGame() {
		gameState = .finished
		stopTimers()
		
		// Save score
		let newScore = GameScore(
			playerName: settings.playerName,
			score: score,
			date: Date()
		)
		self.currentScoreId = newScore.id
		scoreManager.saveScore(newScore)
		highestScore = scoreManager.getHighestScore()
		
		// High scores should be shown
		shouldShowHighScores = true
	}
	
	func resetGame() {
		// Reset game state
		score = 0
		timeRemaining = settings.gameTime
		bubbles = []
		lastPoppedColor = nil
		comboCount = 0
		difficultyFactor = 1.0
		shouldShowHighScores = false
		
		// Stop all timers
		stopTimers()
		
		// Reset game state
		gameState = .setup
	}
	
	// Bubble Management Methods
	func refreshBubbles() {
		// Remove a random number of existing bubbles
		if !bubbles.isEmpty {
			let removalCount = Int.random(in: 1...max(1, bubbles.count / 2))
			let indicesToRemove = Array(0..<bubbles.count).shuffled().prefix(removalCount)
			for index in indicesToRemove.sorted(by: >) {
				if index < bubbles.count {
					bubbles.remove(at: index)
				}
			}
		}
		
		// Calculate how many new bubbles to add
		let targetCount = Int.random(in: 1...settings.maxBubbles)
		let bubblesNeeded = max(0, targetCount - bubbles.count)
		
		// Generate new bubbles
		for _ in 0..<bubblesNeeded {
			addRandomBubble()
		}

		for i in 0..<bubbles.count {
			let radius = bubbles[i].size / 2
			bubbles[i].position.x = max(radius, min(bubbles[i].position.x, screenBounds.width - radius))
			bubbles[i].position.y = max(radius + screenBounds.origin.y, min(bubbles[i].position.y, screenBounds.height - radius + screenBounds.origin.y))
		}
	}
	
	private func addRandomBubble() {
		// Maximum attempts to find non-overlapping position
		let maxAttempts = 100
		var attempts = 0
		
		while attempts < maxAttempts {
			attempts += 1
			
			// Generate random position
			let size = bubbleSize + CGFloat.random(in: -10...10)
			let radius = size / 2
			let padding: CGFloat = 5
			let x = CGFloat.random(in: (radius + padding)...(screenBounds.width - radius - padding))
			let y = CGFloat.random(in: (radius + padding)...(screenBounds.height - radius - padding))
			let position = CGPoint(x: x, y: y)
			
			// Create bubble with random color
			var newBubble = Bubble(
				position: position,
				color: BubbleColor.random(),
				size: size
			)
			
			// Add random velocity for movement
			let maxVelocity = 20.0 * difficultyFactor
			newBubble.velocity = CGVector(
				dx: Double.random(in: -maxVelocity...maxVelocity),
				dy: Double.random(in: -maxVelocity...maxVelocity)
			)
			
			// Check for overlaps with existing bubbles
			if !doesBubbleOverlap(newBubble) {
				bubbles.append(newBubble)
				return
			}
		}
		let smallerSize = bubbleSize * 0.7
		let radius = smallerSize / 2
		let padding: CGFloat = 5
		let x = CGFloat.random(in: (radius + padding)...(screenBounds.width - radius - padding))
		let y = CGFloat.random(in: (radius + padding)...(screenBounds.height - radius - padding))
		
		var newBubble = Bubble(
			position: CGPoint(x: x, y: y),
			color: BubbleColor.random(),
			size: smallerSize
		)
		
		if !doesBubbleOverlap(newBubble) {
			bubbles.append(newBubble)
		}
		
		let maxVelocity = 20.0 * difficultyFactor
		newBubble.velocity = CGVector(
			dx: Double.random(in: -maxVelocity...maxVelocity),
			dy: Double.random(in: -maxVelocity...maxVelocity)
		)
		
		bubbles.append(newBubble)
	}

	private func doesBubbleOverlap(_ newBubble: Bubble) -> Bool {
		for existingBubble in bubbles {
			let dx = newBubble.position.x - existingBubble.position.x
			let dy = newBubble.position.y - existingBubble.position.y
			let distance = sqrt(dx*dx + dy*dy)
			
			// Correct minDistance to sum of radii (size is diameter)
			let minDistance = (newBubble.size + existingBubble.size) / 2
			
			if distance < minDistance {
				return true // Overlap detected
			}
		}
		return false // No overlap
	}
	
	// Bubble Interaction Methods
	func popBubble(at index: Int) {
		guard index < bubbles.count, !bubbles[index].isPopped else { return }
		
		// Mark bubble as popped
		bubbles[index].isPopped = true
		
		// Get bubble's color and base points
		let bubble = bubbles[index]
		let currentColor = bubble.color
		let basePoints = bubble.points
		
		// Check for combo
		var earnedPoints = basePoints
		if let lastColor = lastPoppedColor, lastColor == currentColor {
			comboCount += 1
			earnedPoints = Int(Double(basePoints) * comboMultiplier)
		} else {
			comboCount = 1
		}
		
		// Update score and last popped color
		score += earnedPoints
		lastPoppedColor = currentColor
		lastPoppedTime = Date()
		
		// Remove the bubble after animation
		animatingBubbles[bubble.id] = true
		
		// Remove bubble after a short animation time
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			guard let self = self else { return }
			
			if let index = self.bubbles.firstIndex(where: { $0.id == bubble.id }) {
				self.bubbles.remove(at: index)
			}
			self.animatingBubbles[bubble.id] = nil
		}
	}
	
	// Timer Methods
	private func startTimers() {
		// Main game timer for countdown
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
			guard let self = self, self.gameState == .playing else { return }
			
			self.timeRemaining -= 1
			
			// Increase difficulty over time
			self.difficultyFactor = min(3.0, 1.0 + (Double(self.settings.gameTime - self.timeRemaining) / Double(self.settings.gameTime) * 2.0))
			
			// Check if game is over
			if self.timeRemaining <= 0 {
				self.endGame()
			}
		}
		
		// Bubble refresh timer
		bubbleRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
			guard let self = self, self.gameState == .playing else { return }
			self.refreshBubbles()
		}
		
		// Movement timer
		movementTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
			guard let self = self, self.gameState == .playing else { return }
			self.updateBubblePositions()
		}
	}
	
	private func stopTimers() {
		timer?.invalidate()
		timer = nil
		
		bubbleRefreshTimer?.invalidate()
		bubbleRefreshTimer = nil
		
		movementTimer?.invalidate()
		movementTimer = nil
	}
	
	// Bubble Movement
	private func updateBubblePositions() {
		
		// Calculate time since last update
		let timeElapsed = 0.016 // Approximately 60fps
		
		// Calculate speed factor based on remaining time
		let speedFactor = 1.0 + Double(settings.gameTime - timeRemaining) / Double(settings.gameTime) * 2.0
		
		// Update bubble positions
		for i in 0..<bubbles.count {
			guard animatingBubbles[bubbles[i].id] != true else { continue }
			
			var bubble = bubbles[i]
			let adjustedVelocity = CGVector(
				dx: bubble.velocity.dx * speedFactor,
				dy: bubble.velocity.dy * speedFactor
			)
			
			// Calculate new position
			var newX = bubble.position.x + CGFloat(adjustedVelocity.dx * timeElapsed)
			var newY = bubble.position.y + CGFloat(adjustedVelocity.dy * timeElapsed)
			let radius = bubble.size / 2
			
			// Bounce off edges to stay fully on-screen
			if newX - radius < 0 {
				newX = radius
				bubble.velocity.dx = -bubble.velocity.dx
			} else if newX + radius > screenBounds.width {
				newX = screenBounds.width - radius
				bubble.velocity.dx = -bubble.velocity.dx
			}
			
			// Calculate top and bottom boundaries
			let topBoundary = screenBounds.origin.y
			let bottomBoundary = screenBounds.origin.y + screenBounds.height

			if newY + radius > bottomBoundary {
				// Force it above the boundary with some margin
				newY = bottomBoundary - radius - 1.0  // Add 1.0 pixel margin
				bubble.velocity.dy = -bubble.velocity.dy * 0.95
			}

			// Redundant clamp to handle floating-point errors
			newY = min(max(newY, topBoundary + radius), bottomBoundary - radius)
			
			bubble.position.x = newX
			bubble.position.y = newY

			for i in 0..<bubbles.count {
				let radius = bubbles[i].size / 2
				bubbles[i].position.x = max(radius, min(bubbles[i].position.x, screenBounds.width - radius))
				bubbles[i].position.y = max(radius + screenBounds.origin.y, min(bubbles[i].position.y, screenBounds.origin.y + screenBounds.height - radius))
			}
			
			// Check for collisions with other bubbles
			for j in (i+1)..<bubbles.count {
				guard animatingBubbles[bubbles[j].id] != true else { continue }
				
				var otherBubble = bubbles[j]
				let dx = bubble.position.x - otherBubble.position.x
				let dy = bubble.position.y - otherBubble.position.y
				let distance = sqrt(dx*dx + dy*dy)
				let minDistance = (bubble.size + otherBubble.size) / 2
				
				if distance < minDistance && distance != 0 {
					// Collision detected
					let nx = dx / distance
					let ny = dy / distance
					
					// Separate the bubbles
					let overlap = (minDistance - distance) / 2
					bubble.position.x += nx * overlap
					bubble.position.y += ny * overlap
					otherBubble.position.x -= nx * overlap
					otherBubble.position.y -= ny * overlap
					
					// Reflect velocities
					let velocityI = CGVector(dx: bubble.velocity.dx, dy: bubble.velocity.dy)
					let velocityJ = CGVector(dx: otherBubble.velocity.dx, dy: otherBubble.velocity.dy)
					
					let dotProductI = velocityI.dx * nx + velocityI.dy * ny
					let dotProductJ = velocityJ.dx * nx + velocityJ.dy * ny
					
					bubble.velocity.dx -= 2 * dotProductI * nx
					bubble.velocity.dy -= 2 * dotProductI * ny
					otherBubble.velocity.dx -= 2 * dotProductJ * nx
					otherBubble.velocity.dy -= 2 * dotProductJ * ny
					
					// Update both bubbles in the array
					bubbles[i] = bubble
					bubbles[j] = otherBubble
				}
			}
			
			// Update the bubble in the array after all checks
			bubbles[i] = bubble
			
			// Occasionally change direction to make movement more interesting
			if Int.random(in: 0...500) == 0 {
				bubbles[i].velocity.dx *= -1
			}
			if Int.random(in: 0...500) == 0 {
				bubbles[i].velocity.dy *= -1
			}
		}
		
		enforceBubbleBoundaries()
	}
	
	// Utility Methods
	func updateScreenBounds(_ bounds: CGRect) {
		screenBounds = bounds
		
		// Immediately enforce these bounds on all existing bubbles
		enforceBubbleBoundaries()
	}
	
	// New method to enforce boundaries
	private func enforceBubbleBoundaries() {
		for i in 0..<bubbles.count {
			let radius = bubbles[i].size / 2
			
			// Clamp the x position
			bubbles[i].position.x = max(radius, min(bubbles[i].position.x, screenBounds.width - radius))
			
			// Clamp the y position
			let topBoundary = screenBounds.origin.y + radius
			let bottomBoundary = screenBounds.origin.y + screenBounds.height - radius
			
			// Apply clamping with a small extra buffer for the bottom
			bubbles[i].position.y = max(topBoundary, min(bubbles[i].position.y, bottomBoundary - 5))
		}
	}
	
	// Format time as MM:SS
	var formattedTime: String {
		let minutes = timeRemaining / 60
		let seconds = timeRemaining % 60
		return String(format: "%02d:%02d", minutes, seconds)
	}
	
	// Check if a bubble is being animated
	func isAnimating(_ bubbleId: UUID) -> Bool {
		return animatingBubbles[bubbleId] == true
	}

	func updateSettings(_ newSettings: SettingsModel) {
		self.settings = newSettings
		self.maxBubblesCount = newSettings.maxBubbles
		self.timeRemaining = newSettings.gameTime
	}
}
