//
//  ContentView.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import SwiftUI

struct ContentView: View {
	@State private var isAnimating = false
	@StateObject private var settingsViewModel = SettingsViewModel()
	
	var body: some View {
		NavigationView {
			ZStack {
				// Animated bubbles in background
				BubbleBackgroundView()
				Color.blue.opacity(0.05).edgesIgnoringSafeArea(.all)
				
				// Main
				VStack(spacing: 90) {
					Spacer()
					// Title
					Text("Bubble Pop")
						.font(.system(size: 46, weight: .bold))
						.foregroundColor(.black)
						.scaleEffect(isAnimating ? 1.0 : 0.8)
						.opacity(isAnimating ? 1.0 : 0.0)
						.animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), value: isAnimating)
					
					// Game buttons
					VStack(spacing: 40) {
						NavigationLink(destination: GameView().environmentObject(settingsViewModel)) {
							ButtonView(title: "New Game", icon: "play.circle.fill", color: .orange)
						}
						
						NavigationLink(destination: HighScoreView()) {
							ButtonView(title: "High Scores", icon: "star.fill", color: .brown)
						}
						
						NavigationLink(destination: SettingsView().environmentObject(settingsViewModel)) {
							ButtonView(title: "Settings", icon: "gear", color: .gray)
						}
					}
					.scaleEffect(isAnimating ? 1.0 : 0.8)
					.opacity(isAnimating ? 1.0 : 0.0)
					.animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0).delay(0.2), value: isAnimating)
					
					Spacer()
					
					// Copyright
					Text("© 2025 ZZ BubblePop")
						.font(.caption)
						.foregroundColor(.gray.opacity(0.7))
						.padding(.bottom, 10)
						.opacity(isAnimating ? 1.0 : 0.0)
						.animation(.easeIn.delay(0.5), value: isAnimating)
				}
				.padding()
			}
			.onAppear {
				// Trigger animations when view appears
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
					isAnimating = true
				}
			}
			.navigationBarHidden(true)
		}
		.navigationViewStyle(StackNavigationViewStyle())
		.environmentObject(settingsViewModel)
	}
}

// Button View
struct ButtonView: View {
	let title: String
	let icon: String
	let color: Color
	
	var body: some View {
		HStack {
			Image(systemName: icon)
				.font(.system(size: 24))
				.foregroundColor(.white)
				.frame(width: 50)
			
			Text(title)
				.font(.system(size: 22, weight: .semibold))
				.foregroundColor(.white)
			
			Spacer()
			
			Image(systemName: "chevron.right")
				.foregroundColor(.white.opacity(0.9))
				.padding(.trailing, 10)
		}
		.padding(.vertical, 15)
		.padding(.horizontal, 20)
		.background(color)
		.cornerRadius(15)
		.shadow(color: color.opacity(0.5), radius: 5, x: 0, y: 3)
	}
}

// Animated Background Bubbles
struct BubbleBackgroundView: View {
	// Properties for animated background bubbles
	let bubbleCount = 15
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				ForEach(0..<bubbleCount, id: \.self) { index in
					BackgroundBubble(
						size: CGFloat.random(in: 30...70),
						position: randomPosition(in: geometry.size),
						color: randomColor(),
						animationDuration: Double.random(in: 8...15),
						delay: Double.random(in: 0...3)
					)
				}
			}
			.frame(width: geometry.size.width, height: geometry.size.height)
		}
	}
	
	// Generate random position for bubbles
	private func randomPosition(in size: CGSize) -> CGPoint {
		return CGPoint(
			x: CGFloat.random(in: 0...size.width),
			y: CGFloat.random(in: 0...size.height)
		)
	}
	
	// Generate random bubble color
	private func randomColor() -> Color {
		let colors: [Color] = [.red, .pink, .green, .blue, .black]
		return colors.randomElement() ?? .blue
	}
}

// Background Bubble
struct BackgroundBubble: View {
	let size: CGFloat
	let position: CGPoint
	let color: Color
	let animationDuration: Double
	let delay: Double
	
	@State private var animating = false
	
	var body: some View {
		Circle()
			.fill(color.opacity(0.3))
			.frame(width: size, height: size)
			.position(
				x: animating ? position.x + CGFloat.random(in: -100...100) : position.x,
				y: animating ? position.y + CGFloat.random(in: -100...100) : position.y
			)
			.animation(
				Animation
					.easeInOut(duration: animationDuration)
					.repeatForever(autoreverses: true)
					.delay(delay),
				value: animating
			)
			.onAppear {
				animating = true
			}
	}
}

#Preview {
	ContentView()
}
