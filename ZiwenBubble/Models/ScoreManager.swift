//
//  ScoreManager.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.17.
//

import Foundation

class ScoreManager {
	// Maximum number of high scores to keep
	private let maxScores = 10
	
	// UserDefaults key for storing scores
	private let scoresKey = "BubblePopHighScores"
	
	// Retrieves all saved scores
	func getAllScores() -> [GameScore] {
		guard let savedScores = UserDefaults.standard.data(forKey: scoresKey),
			  let decodedScores = try? JSONDecoder().decode([GameScore].self, from: savedScores) else {
			return []
		}
		
		return decodedScores.sorted()
	}
	
	// Saves a new score and maintains the high score list
	func saveScore(_ newScore: GameScore) {
		var scores = getAllScores()
		scores.append(newScore)
		scores.sort() // Sort by score in descending order
		
		// Keep only the top scores
		if scores.count > maxScores {
			scores = Array(scores.prefix(maxScores))
		}
		
		// Save back to UserDefaults
		if let encoded = try? JSONEncoder().encode(scores) {
			UserDefaults.standard.set(encoded, forKey: scoresKey)
		}
	}
	
	// Clears all saved scores
	func clearScores() {
		UserDefaults.standard.removeObject(forKey: scoresKey)
	}
	
	// Gets the highest score
	func getHighestScore() -> Int {
		let scores = getAllScores()
		return scores.first?.score ?? 0
	}
}
