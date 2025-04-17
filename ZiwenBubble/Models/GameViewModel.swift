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
		
		scoreManager.saveScore(newScore)
		highestScore = scoreManager.getHighestScore()
	}
	
	func resetGame() {
		// Reset game state
		score = 0
		timeRemaining = settings.gameTime
		bubbles = []
		lastPoppedColor = nil
		comboCount = 0
		difficultyFactor = 1.0
		
		// Stop all timers
		stopTimers()
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
	}
	
	private func addRandomBubble() {
		// Maximum attempts to find non-overlapping position
		let maxAttempts = 50
		var attempts = 0
		
		while attempts < maxAttempts {
			attempts += 1
			
			// Generate random position
			let size = bubbleSize + CGFloat.random(in: -10...10)
			let radius = size / 2
			let x = CGFloat.random(in: radius...(screenBounds.width - radius))
			let y = CGFloat.random(in: radius...(screenBounds.height - radius))
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
			if !bubbles.contains(where: { newBubble.overlaps(with: $0, inBounds: screenBounds) }) {
				bubbles.append(newBubble)
				break
			}
		}
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
		
		// Update bubble positions
		for i in 0..<bubbles.count {
			// Skip bubbles that are being animated for removal
			if animatingBubbles[bubbles[i].id] == true {
				continue
			}
			
			// Move the bubble
			bubbles[i].move(bounds: screenBounds, timeElapsed: timeElapsed)
			
			// Check if bubble is out of bounds
			if !bubbles[i].isInBounds(screenBounds) {
				// Remove the bubble if it's out of bounds
				bubbles.remove(at: i)
				break
			}
		}
	}
	
	// Utility Methods
	func updateScreenBounds(_ bounds: CGRect) {
		screenBounds = bounds
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
