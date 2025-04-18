//
//  GameView.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import SwiftUI

struct GameView: View {
	// Properties
	@EnvironmentObject var settingsViewModel: SettingsViewModel
    @StateObject private var viewModel: GameViewModel
    @State private var screenSize: CGSize = UIScreen.main.bounds.size
    @Environment(\.presentationMode) var presentationMode
    @State private var showSettings = false
    @State private var showPauseMenu = false
    @State private var showHighScores = false
	
	// Initializer with default settings
	init() {
		// Set default value
		let defaultSettings = SettingsModel(playerName: "Player", gameTime: 60, maxBubbles: 15)
		_viewModel = StateObject(wrappedValue: GameViewModel(settings: defaultSettings))
	}

	// Game Body
	var body: some View {
		ZStack {
            
            // Main game content
            gameContent(viewModel)
            
            // Settings Sheet
            if showSettings {
                SettingsView()
                    .environmentObject(settingsViewModel)
                    .transition(.move(edge: .bottom))
                    .onDisappear {
                        // Only initialize if we're coming back from settings
                        if settingsViewModel.areSettingsValid {
                            initializeGame()
                        }
                    }
            }
            
            // Pause Menu
            if showPauseMenu {
                pauseMenu
            }
            
            // Game Over
			if showHighScores {
				HighScoreView(
					currentPlayerName: settingsViewModel.playerName,
					currentScore: viewModel.score
				)
				.transition(.opacity)
				.zIndex(3)
			}
        }
		.navigationBarHidden(true)
		.onAppear {
            initializeGame()
        }
        .onChange(of: screenSize) { _, newValue in
            viewModel.updateScreenBounds(CGRect(origin: .zero, size: newValue))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let newSize = UIScreen.main.bounds.size
            screenSize = newSize
        }
	}
	
	// Game Content
	private func gameContent(_ viewModel: GameViewModel) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Game area
				Color.blue.opacity(0.05).edgesIgnoringSafeArea(.all)
                
				// Show different views based on game state
				if viewModel.shouldShowHighScores {
					// Show high scores when game is finished
					HighScoreView(currentPlayerName: settingsViewModel.playerName, currentScore: viewModel.score)
						.transition(.opacity)
						.onDisappear {
							// Reset when high scores view is dismissed
							viewModel.shouldShowHighScores = false
						}
				} else {
					// Game state dependent views
					ZStack {
						// Bubble game area
						if viewModel.gameState == .playing || viewModel.gameState == .paused {
							bubbleGameArea(viewModel, size: geometry.size)
						}
						
						// Starting countdown
						if viewModel.gameState == .starting {
							countdownView(viewModel)
						}
						
						// Game controls overlay
						VStack {
							// Top bar with score and time
							gameInfoBar(viewModel)
							
							Spacer()
							
							// Bottom controls
							gameControlBar(viewModel)
						}
						.padding()
					}
				}
            }
			.onAppear {
				// Get the window scene's safe area insets
				let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
				let safeAreaInsets = windowScene?.windows.first?.safeAreaInsets ?? UIEdgeInsets()
				
				// Create adjusted bounds that account for safe areas
				let adjustedBounds = CGRect(
					x: 0,
					y: safeAreaInsets.top,
					width: geometry.size.width,
					height: geometry.size.height - safeAreaInsets.top - safeAreaInsets.bottom
				)
				
				// Apply a safety margin for the bottom edge specifically
				let safetyMargin: CGFloat = 20.0  // Add extra margin at bottom
				let finalBounds = CGRect(
					x: adjustedBounds.origin.x,
					y: adjustedBounds.origin.y,
					width: adjustedBounds.width,
					height: adjustedBounds.height - safetyMargin
				)
				
				viewModel.updateScreenBounds(finalBounds)
			}
        }
    }
    	
	// Game info bar (score, time)
	private func gameInfoBar(_ viewModel: GameViewModel) -> some View {
		HStack {
			// Score display
			VStack(alignment: .leading) {
				Text("Score")
					.font(.headline)
				Text("\(viewModel.score)")
					.font(.title)
					.fontWeight(.bold)
					.foregroundColor(.orange)
			}
			
			Spacer()
			
			// Highest score display
			VStack(alignment: .center) {
				Text("Highest")
					.font(.headline)
				Text("\(viewModel.highestScore)")
					.font(.title)
					.fontWeight(.bold)
					.foregroundColor(.black)
			}
			
			Spacer()
			
			// Time remaining display
			VStack(alignment: .trailing) {
				Text("Time")
					.font(.headline)
				Text(viewModel.formattedTime)
					.font(.title)
					.fontWeight(.bold)
					.foregroundColor(viewModel.timeRemaining <= 10 ? .red : .black)
			}
		}
		.padding()
	}
	
	// Game control bar
	private func gameControlBar(_ viewModel: GameViewModel) -> some View {
		HStack {
			// Pause/Resume button
			Button(action: {
				if viewModel.gameState == .playing {
					viewModel.pauseGame()
					showPauseMenu = true
				} else if viewModel.gameState == .paused {
					viewModel.resumeGame()
					showPauseMenu = false
				}
			}) {
				Image(systemName: viewModel.gameState == .playing ? "pause.circle.fill" : "play.circle.fill")
					.font(.system(size: 36))
					.foregroundColor(.orange.opacity(0.8))
			}
			.disabled(viewModel.gameState != .playing && viewModel.gameState != .paused)
						
			Spacer()
			
			// Show combo count if applicable
			if viewModel.comboCount > 1 {
				Text("Combo: x1.5")
					.font(.title3)
					.fontWeight(.bold)
					.foregroundColor(.orange)
					.transition(.scale)
			}
			
			Spacer()
			
		}
		.padding()
	}
	
	// Bubble game area
	private func bubbleGameArea(_ viewModel: GameViewModel, size: CGSize) -> some View {
		ZStack {
			// Bubbles
			ForEach(Array(viewModel.bubbles.enumerated()), id: \.element.id) { index, bubble in
				BubbleView(bubble: bubble, isAnimating: viewModel.isAnimating(bubble.id))
					.position(bubble.position)
					.onTapGesture {
						withAnimation(.easeOut(duration: 0.3)) {
							viewModel.popBubble(at: index)
						}
					}
			}
		}
		.frame(width: size.width, height: size.height)
	}
	
	// Countdown view
	private func countdownView(_ viewModel: GameViewModel) -> some View {
		VStack {
			Text("\(viewModel.countdownValue)")
				.font(.system(size: 120, weight: .bold))
				.foregroundColor(.black.opacity(0.9))
				.transition(.scale)
				.id(viewModel.countdownValue) // Force view recreation for animation
				.animation(.easeInOut(duration: 0.5), value: viewModel.countdownValue)
			
			Text("Get Ready!")
				.font(.title)
				.foregroundColor(.gray)
		}
	}
	
	// Pause menu
	private var pauseMenu: some View {
		ZStack {
			// Background Color
			Color.black.opacity(0.4)
				.edgesIgnoringSafeArea(.all)
			
			// Main content container
			VStack(spacing: 20) {
				Text("Game Paused")
					.font(.largeTitle)
					.fontWeight(.bold)
					.foregroundColor(.white)
				
				// Buttons
				Group {
					Button("Resume") {
						viewModel.resumeGame()
						showPauseMenu = false
					}
					Button("Restart") {
						viewModel.resetGame()
						viewModel.startGame()
						showPauseMenu = false
					}
					Button("Menu") {
						presentationMode.wrappedValue.dismiss()
					}
				}
				.font(.title2)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity, minHeight: 15)
				.padding()
				.background(
					RoundedRectangle(cornerRadius: 20)
						.fill(Color.white.opacity(0.2))
				)
			}
			.padding()
			.background(Color.gray)
			.cornerRadius(20)
			.padding(.horizontal, 30)
			.frame(maxWidth: .infinity)
		}
		.zIndex(2)
	}
	
	// Initialize the game with current settings
    private func initializeGame() {
        let settings = SettingsModel(
            playerName: settingsViewModel.playerName,
            gameTime: settingsViewModel.gameTime,
            maxBubbles: settingsViewModel.maxBubbles
        )
        
        // Update the existing view model with new settings
        viewModel.updateSettings(settings)
        
        // Auto-start if settings are valid
        if settingsViewModel.areSettingsValid {
            viewModel.startGame()
        } else {
            // Show settings sheet if needed
            showSettings = true
        }
    }
}

// Bubble View
struct BubbleView: View {
	let bubble: Bubble
	let isAnimating: Bool
	
	var body: some View {
		Circle()
			.fill(bubble.color.uiColor)
			.frame(width: bubble.size, height: bubble.size)
			.overlay(
				Circle()
					.stroke(Color.white, lineWidth: 2)
			)
			.shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 1)
			.scaleEffect(isAnimating ? 1.2 : 1.0)
			.opacity(isAnimating ? 0 : 1.0)
			.animation(.easeOut(duration: 0.3), value: isAnimating)
			.overlay(
				ZStack {
					// Add visual effects for popped bubbles
					if isAnimating {
						Circle()
							.stroke(bubble.color.uiColor, lineWidth: 2)
							.scaleEffect(1.5)
							.opacity(0)
							.animation(.easeOut(duration: 0.3), value: isAnimating)
					}
					
					// Display points for high-value bubbles
					if bubble.points >= 5 {
						Text("\(bubble.points)")
							.font(.system(size: bubble.size * 0.4))
							.foregroundColor(.white)
							.fontWeight(.bold)
					}
				}
			)
	}
}

#Preview {
	GameView()
		.environmentObject(SettingsViewModel())
}
