//
//  SettingsModel.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import Foundation

struct SettingsModel: Codable {
	// Player information
	var playerName: String
	
	// Game settings with default values
	var gameTime: Int
	var maxBubbles: Int
	
	// Initialize with default values
	init(playerName: String = "", gameTime: Int = 60, maxBubbles: Int = 15) {
		self.playerName = playerName
		self.gameTime = gameTime
		self.maxBubbles = maxBubbles
	}
}
