//
//  GameSetupView.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.21.
//

import SwiftUI

struct GameSetupView: View {
	@EnvironmentObject var settingsViewModel: SettingsViewModel
	@Environment(\.presentationMode) var presentationMode
	@State private var showAlert = false
	@State private var alertMessage = ""
	@State private var tempName: String = ""
	@State private var tempGameTime: Int = 60
	@State private var tempMaxBubbles: Int = 15
	
	var onStartGame: () -> Void
	
	var body: some View {
		Form {
			Section(header: Text("Player Information")) {
				TextField("Enter your name", text: $tempName)
					.autocapitalization(.words)
					.disableAutocorrection(true)
			}
			
			Section(header: Text("Game Settings")) {
				HStack {
					Text("Game Time (Seconds)")
					Spacer()
					TextField("", value: $tempGameTime, format: .number)
						.keyboardType(.numberPad)
						.multilineTextAlignment(.trailing)
						.frame(width: 60)
				}
				
				// Game time slider
				Slider(value: Binding(
					get: { Double(tempGameTime) },
					set: { tempGameTime = Int($0) }
				), in: Double(settingsViewModel.minGameTime)...Double(settingsViewModel.maxGameTime), step: 1)
				
				Text("Range: \(settingsViewModel.minGameTime)-\(settingsViewModel.maxGameTime) Seconds")
					.font(.caption)
					.foregroundColor(isGameTimeValid ? .gray : .red)
				
				HStack {
					Text("Maximum Bubbles")
					Spacer()
					TextField("", value: $tempMaxBubbles, format: .number)
						.keyboardType(.numberPad)
						.multilineTextAlignment(.trailing)
						.frame(width: 60)
				}
				
				// Max bubbles slider
				Slider(value: Binding(
					get: { Double(tempMaxBubbles) },
					set: { tempMaxBubbles = Int($0) }
				), in: Double(settingsViewModel.minBubbles)...Double(settingsViewModel.maxBubblesLimit), step: 1)
				
				Text("Range: \(settingsViewModel.minBubbles)-\(settingsViewModel.maxBubblesLimit) Bubbles")
					.font(.caption)
					.foregroundColor(isMaxBubblesValid ? .gray : .red)
			}
			
			Section {
				Button("Start Game") {
					validateAndStartGame()
				}
				.frame(maxWidth: .infinity)
				.disabled(!areSettingsValid)
			}
			
			Section {
				Button("Back") {
					presentationMode.wrappedValue.dismiss()
				}
				.frame(maxWidth: .infinity)
			}
		}
		.formStyle(.grouped)
		.navigationTitle("Game Setup")
		.navigationBarTitleDisplayMode(.inline)
		.alert(isPresented: $showAlert) {
			Alert(
				title: Text("Invalid Settings"),
				message: Text(alertMessage),
				dismissButton: .default(Text("OK"))
			)
		}
		.onAppear {
			// Set default values when view appears
			tempName = ""
			tempGameTime = 60
			tempMaxBubbles = 15
		}

		.navigationViewStyle(StackNavigationViewStyle())
	}
	
	// Validation properties
	private var isGameTimeValid: Bool {
		return tempGameTime >= settingsViewModel.minGameTime && tempGameTime <= settingsViewModel.maxGameTime
	}
	
	private var isMaxBubblesValid: Bool {
		return tempMaxBubbles >= settingsViewModel.minBubbles && tempMaxBubbles <= settingsViewModel.maxBubblesLimit
	}
	
	private var isPlayerNameValid: Bool {
		return !tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
	
	private var areSettingsValid: Bool {
		return isPlayerNameValid && isGameTimeValid && isMaxBubblesValid
	}
	
	// Validates settings before starting the game
	private func validateAndStartGame() {
		// Check if player name is valid
		if !isPlayerNameValid {
			alertMessage = "Please enter your name."
			showAlert = true
			return
		}
		
		// Check if game time is valid
		if !isGameTimeValid {
			alertMessage = "Game time must be between \(settingsViewModel.minGameTime) and \(settingsViewModel.maxGameTime) seconds."
			showAlert = true
			return
		}
		
		// Check if max bubbles is valid
		if !isMaxBubblesValid {
			alertMessage = "Maximum bubbles must be between \(settingsViewModel.minBubbles) and \(settingsViewModel.maxBubblesLimit)."
			showAlert = true
			return
		}
		
		// Update all the valid settings in ViewModel
		settingsViewModel.playerName = tempName
		settingsViewModel.gameTime = tempGameTime
		settingsViewModel.maxBubbles = tempMaxBubbles
		
		// Save the settings
		settingsViewModel.saveSettings()
		
		// Start the game
		onStartGame()
		
	}
}

#Preview {
	GameSetupView(onStartGame: {})
		.environmentObject(SettingsViewModel())
}
