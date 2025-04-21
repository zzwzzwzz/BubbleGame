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
	@State private var showGameRules = false
	@EnvironmentObject var navigationManager: NavigationManager
	
	// Initializer with default settings
	init() {
		let settings = SettingsModel(
			playerName: SettingsViewModel().playerName,
			gameTime: SettingsViewModel().gameTime,
			maxBubbles: SettingsViewModel().maxBubbles
		)
		_viewModel = StateObject(wrappedValue: GameViewModel(settings: settings))
	}

	// Game Body
	var body: some View {
		ZStack {
            
            // Main game content
            gameContent(viewModel)
            
            // Settings Sheet
			if showSettings {
				NavigationView {
					SettingsView(startNewGame: {
						navigationManager.path.append("game")
					})
						.environmentObject(settingsViewModel)
				}
				.navigationViewStyle(StackNavigationViewStyle())
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
			
			if showGameRules {
				gameRulesView
					.transition(.opacity)
			}
			
            // Game Over
			if showHighScores {
				HighScoreView(
					currentPlayerName: settingsViewModel.playerName,
					currentScore: viewModel.score,
					currentScoreId: viewModel.currentScoreId
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
					HighScoreView(
						currentPlayerName: settingsViewModel.playerName,
						currentScore: viewModel.score,
						currentScoreId: viewModel.currentScoreId
					)
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
			
			// Help/Info button (NEW)
			Button(action: {
				if viewModel.gameState == .playing {
					viewModel.pauseGame()
				}
				showGameRules = true
			}) {
				Image(systemName: "questionmark.circle.fill")
					.font(.system(size: 36))
					.foregroundColor(.orange.opacity(0.8))
			}
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
					.buttonStyle(PrimaryButtonStyle())
					Button("Restart") {
						viewModel.resetGame()
						viewModel.startGame()
						showPauseMenu = false
					}
					.buttonStyle(PrimaryButtonStyle())
					Button("Menu") {
						navigationManager.popToRoot()
					}
					.buttonStyle(PrimaryButtonStyle())
				}
			}
			.padding()
			.background(Color.gray)
			.cornerRadius(20)
			.padding(.horizontal, 30)
			.frame(maxWidth: .infinity)
		}
		.zIndex(2)
	}
	
	private var gameRulesView: some View {
		ZStack {
			// Background
			Color.black.opacity(0.4)
				.edgesIgnoringSafeArea(.all)
			
			// Content
			VStack(spacing: 10) {
				Text("Game Rules")
					.font(.largeTitle)
					.fontWeight(.bold)
					.foregroundColor(.white)
				
				pointsTable
				
				comboRulesSection
				
				gameplayTipsSection
				
				dismissButton
			}
			.padding()
			.background(Color.gray.opacity(0.8))
			.cornerRadius(20)
			.padding(.horizontal, 30)
		}
		.zIndex(2)
	}

	private var pointsTable: some View {
		VStack(spacing: 10) {
			Text("Points")
				.font(.title3)
				.fontWeight(.bold)
				.foregroundColor(.white)
				.padding(.bottom, 5)
			
			// Table Header
			HStack {
				Text("Color").frame(width: 80, alignment: .leading)
				Text("Points").frame(width: 60, alignment: .center)
				Text("Chance").frame(width: 80, alignment: .trailing)
			}
			.font(.headline)
			.foregroundColor(.white)
			
			Divider().background(Color.white)
			
			// Table Rows
			ForEach(bubbleData, id: \.color) { bubble in
				HStack {
					Circle()
						.fill(bubble.color)
						.frame(width: 20, height: 20)
					Text(bubble.name).frame(width: 80, alignment: .leading)
					Text("\(bubble.points)").frame(width: 60)
					Text(bubble.probability).frame(width: 80)
				}
				.foregroundColor(.white)
			}
		}
		.padding()
		.background(Color.white.opacity(0.2))
		.cornerRadius(15)
	}

	private var comboRulesSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Combo")
				.font(.title3)
				.fontWeight(.bold)
				.foregroundColor(.white)
			
			Text("• Consecutive same-color pops")
			Text("• 1.5x multiplier after first bubble")
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.foregroundColor(.white)
	}

	private var gameplayTipsSection: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Tips")
				.font(.title3)
				.fontWeight(.bold)
				.foregroundColor(.white)
			
			Text("• Tap bubbles quickly for combos")
			Text("• Prioritize high-value bubbles")
			Text("• Watch the timer!")
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.foregroundColor(.white)
	}

	private var dismissButton: some View {
		Button("Got it!") {
			showGameRules = false
			if viewModel.gameState == .paused {
				viewModel.resumeGame()
			}
		}
		.buttonStyle(PrimaryButtonStyle())
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
		
		// Autostart if settings are valid
		if settingsViewModel.areSettingsValid {
			viewModel.startGame()
		} else {
			// Show settings sheet
			showSettings = true
		}
	}
}

// Game Rule style
struct PrimaryButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.font(.title2.weight(.semibold))
			.foregroundColor(.white)
			.padding()
			.frame(maxWidth: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 15)
					.fill(Color.orange.opacity(0.8))
			)
			.scaleEffect(configuration.isPressed ? 0.95 : 1)
	}
}

private let bubbleData = [
	BubbleInfo(color: .red, name: "Red", points: 1, probability: "40%"),
	BubbleInfo(color: .pink, name: "Pink", points: 2, probability: "30%"),
	BubbleInfo(color: .green, name: "Green", points: 5, probability: "15%"),
	BubbleInfo(color: .blue, name: "Blue", points: 8, probability: "10%"),
	BubbleInfo(color: .black, name: "Black", points: 10, probability: "5%")
]

struct BubbleInfo {
	let color: Color
	let name: String
	let points: Int
	let probability: String
}

// Bubble View
struct BubbleView: View {
	let bubble: Bubble
	let isAnimating: Bool
	
	var body: some View {
		let lighterColor = bubble.color.uiColor.opacity(0.7)
		let gradient = RadialGradient(
			gradient: Gradient(colors: [
				.white.opacity(0.6),
				lighterColor,
				lighterColor.opacity(0.3)
			]),
			center: .topLeading,
			startRadius: 0,
			endRadius: 50
		)
		
		Circle()
			.fill(gradient)
			.frame(width: bubble.size, height: bubble.size)
			.overlay(
				Circle()
					.stroke(
						LinearGradient(
							gradient: Gradient(colors: [.white.opacity(0.5), .clear]),
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 3
					)
			)
			.overlay( // Bubble highlight
				Circle()
					.trim(from: 0, to: 0.4)
					.stroke(
						LinearGradient(
							gradient: Gradient(colors: [.white.opacity(0.8), .clear]),
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 4
					)
					.rotationEffect(.degrees(-30))
					.offset(x: bubble.size * 0.15, y: -bubble.size * 0.15)
			)
			.shadow(color: .blue.opacity(0.2), radius: 8, x: 2, y: 2)
			.shadow(color: .black.opacity(0.1), radius: 3, x: -1, y: -1)
			.scaleEffect(isAnimating ? 1.2 : 1.0)
			.opacity(isAnimating ? 0 : 1.0)
			.animation(.easeOut(duration: 0.3), value: isAnimating)
			.overlay(
				ZStack {
					if isAnimating {
						Circle()
							.stroke(lighterColor, lineWidth: 2)
							.scaleEffect(1.5)
							.opacity(0)
							.animation(.easeOut(duration: 0.3), value: isAnimating)
					}
				}
			)
			.scaleEffect(isAnimating ? 1.2 : 1.0)
			.animation(
				.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
				value: isAnimating
			)
	}
}

#Preview {
	GameView()
		.environmentObject(SettingsViewModel())
}
