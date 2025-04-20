//
//  SettingsView.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import SwiftUI

struct SettingsView: View {
	@EnvironmentObject var viewModel: SettingsViewModel
	@Environment(\.presentationMode) var presentationMode
	@State private var showAlert = false
	@State private var alertMessage = ""
	
	var body: some View {
		Form {
			Section(header: Text("Player Information")) {
				TextField("Enter your name", text: $viewModel.playerName)
					.autocapitalization(.words)
					.disableAutocorrection(true)
					.onChange(of: viewModel.playerName) {
						viewModel.saveSettings()
					}
			}
			
			Section(header: Text("Game Settings")) {
				HStack {
					Text("Game Time (Seconds)")
					Spacer()
					TextField("", value: $viewModel.gameTime, format: .number)
						.keyboardType(.numberPad)
						.multilineTextAlignment(.trailing)
						.frame(width: 60)
						.onChange(of: viewModel.gameTime) {
							viewModel.saveSettings()
						}
				}
				
				// Game time slider
				Slider(value: Binding(
					get: { Double(viewModel.gameTime) },
					set: { viewModel.gameTime = Int($0) }
				), in: Double(viewModel.minGameTime)...Double(viewModel.maxGameTime), step: 1)
				
				Text("Range: \(viewModel.minGameTime)-\(viewModel.maxGameTime) Seconds")
					.font(.caption)
					.foregroundColor(viewModel.isGameTimeValid ? .gray : .red)
				
				HStack {
					Text("Maximum Bubbles")
					Spacer()
					TextField("", value: $viewModel.maxBubbles, format: .number)
						.keyboardType(.numberPad)
						.multilineTextAlignment(.trailing)
						.frame(width: 60)
						.onChange(of: viewModel.maxBubbles) {
							viewModel.saveSettings()
						}
				}
				
				// Max bubbles slider
				Slider(value: Binding(
					get: { Double(viewModel.maxBubbles) },
					set: { viewModel.maxBubbles = Int($0) }
				), in: Double(viewModel.minBubbles)...Double(viewModel.maxBubblesLimit), step: 1)
				
				Text("Range: \(viewModel.minBubbles)-\(viewModel.maxBubblesLimit) Bubbles")
					.font(.caption)
					.foregroundColor(viewModel.isMaxBubblesValid ? .gray : .red)
			}
			
			Section {
				Button("Start New Game") {
					validateAndStartGame()
				}
				.frame(maxWidth: .infinity)
				.disabled(!viewModel.areSettingsValid)
			}
			
			Section {
				Button("Back to Menu") {
					presentationMode.wrappedValue.dismiss()
				}
				.frame(maxWidth: .infinity)
			}
		}
		.formStyle(.grouped)
		.navigationTitle("Game Settings")
		.navigationBarTitleDisplayMode(.inline)
		.alert(isPresented: $showAlert) {
			Alert(
				title: Text("Invalid Settings"),
				message: Text(alertMessage),
				dismissButton: .default(Text("OK"))
			)
		}
	}
	
	// Validates settings before starting the game
	private func validateAndStartGame() {
		// Check if player name is valid
		if viewModel.playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
			alertMessage = "Please enter your name."
			showAlert = true
			return
		}
		
		// Check if game time is valid
		if viewModel.gameTime < viewModel.minGameTime || viewModel.gameTime > viewModel.maxGameTime {
			alertMessage = "Game time must be between \(viewModel.minGameTime) and \(viewModel.maxGameTime) seconds."
			showAlert = true
			return
		}
		
		// Check if max bubbles is valid
		if viewModel.maxBubbles < viewModel.minBubbles || viewModel.maxBubbles > viewModel.maxBubblesLimit {
			alertMessage = "Maximum bubbles must be between \(viewModel.minBubbles) and \(viewModel.maxBubblesLimit)."
			showAlert = true
			return
		}
		
		// All settings are valid, save settings and dismiss
		viewModel.saveSettings()
		presentationMode.wrappedValue.dismiss()
	}
}

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
}
