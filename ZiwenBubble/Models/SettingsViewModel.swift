//
//  SettingsViewModel.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import Foundation
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
	// Published properties that the view can observe
	@Published var playerName: String = ""
	@Published var gameTime: Int = 60
	@Published var maxBubbles: Int = 15
	
	// Validation properties
	@Published var isPlayerNameValid: Bool = false
	@Published var isGameTimeValid: Bool = true
	@Published var isMaxBubblesValid: Bool = true
	
	// Minimum and maximum values for game settings
	let minGameTime = 1
	let maxGameTime = 60
	let minBubbles = 1
	let maxBubblesLimit = 15
	
	// UserDefaults key for storing settings
	private let settingsKey = "BubblePopSettings"
	
	// Cancellables for managing Combine subscriptions
	private var cancellables = Set<AnyCancellable>()
	
	init() {
		// Load settings from persistent storage
		loadSettings()
		
		// Set up validation for player name
		$playerName
			.map { name in
				// Consider empty string as invalid
				return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
			}
			.assign(to: &$isPlayerNameValid)
		
		// Set up validation for game time
		$gameTime
			.map { $0 >= self.minGameTime && $0 <= self.maxGameTime }
			.assign(to: &$isGameTimeValid)
		
		// Set up validation for max bubbles
		$maxBubbles
			.map { $0 >= self.minBubbles && $0 <= self.maxBubblesLimit }
			.assign(to: &$isMaxBubblesValid)
	}
	
	// Saves current settings to UserDefaults
	func saveSettings() {
		let settings = SettingsModel(
			playerName: playerName,
			gameTime: gameTime,
			maxBubbles: maxBubbles
		)
		
		if let encoded = try? JSONEncoder().encode(settings) {
			UserDefaults.standard.set(encoded, forKey: settingsKey)
		}
	}
	
	// Loads settings from UserDefaults
	private func loadSettings() {
		if let savedSettings = UserDefaults.standard.data(forKey: settingsKey),
		   let decodedSettings = try? JSONDecoder().decode(SettingsModel.self, from: savedSettings) {
			self.playerName = decodedSettings.playerName
			self.gameTime = decodedSettings.gameTime
			self.maxBubbles = decodedSettings.maxBubbles
		}
	}
	
	// Validates if all settings are correct
	var areSettingsValid: Bool {
		return isPlayerNameValid && isGameTimeValid && isMaxBubblesValid
	}
}
