//
//  HighScoreView.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import SwiftUI

struct HighScoreView: View {
	// Properties
	@State private var scores: [GameScore] = []
	@State private var isAnimating = false
	@Environment(\.presentationMode) var presentationMode
	private let scoreManager = ScoreManager()
	
	// Body
	var body: some View {
		ZStack {
			// Background color
			Color.blue.opacity(0.05).edgesIgnoringSafeArea(.all)
			VStack {
				// Header
				Text("High Scores")
					.font(.system(size: 36, weight: .bold))
					.foregroundColor(.black)
					.padding(.top, 20)
				
				// Scores list
				if scores.isEmpty {
					Spacer()
					Text("No scores yet!")
						.font(.title)
						.foregroundColor(.white.opacity(0.8))
					Spacer()
				} else {
					scoresList
				}
				
				// Buttons
				HStack(spacing: 20) {
					Button(action: {
						presentationMode.wrappedValue.dismiss()
					}) {
						Text("Back")
							.font(.title2)
							.foregroundColor(.white)
							.padding(.horizontal, 30)
							.padding(.vertical, 10)
							.background(Color.gray)
							.cornerRadius(15)
					}
					
					Button(action: {
						clearScores()
					}) {
						Text("Clear All")
							.font(.title2)
							.foregroundColor(.white)
							.padding(.horizontal, 30)
							.padding(.vertical, 10)
							.background(Color.red.opacity(0.9))
							.cornerRadius(15)
					}
				}
				.padding(.bottom, 30)
			}
			.padding()
			.onAppear {
				loadScores()
				animateScores()
			}
		}
		.navigationBarHidden(true)
	}
	
	// Score List View
	private var scoresList: some View {
		ScrollView {
			VStack(spacing: 10) {
				// Table header
				HStack {
					Text("Rank")
						.font(.headline)
						.frame(width: 60, alignment: .center)
					
					Text("Player")
						.font(.headline)
						.frame(maxWidth: .infinity, alignment: .leading)
					
					Text("Score")
						.font(.headline)
						.frame(width: 80, alignment: .trailing)
				}
				.foregroundColor(.white)
				.padding(.vertical, 10)
				.padding(.horizontal, 15)
				.background(Color.black.opacity(0.4))
				.cornerRadius(10)
				
				// Score rows
				ForEach(Array(scores.enumerated()), id: \.element.id) { index, score in
					ScoreRowView(rank: index + 1, score: score, isAnimating: isAnimating)
						.transition(.scale)
						.animation(
							.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
							.delay(Double(index) * 0.1),
							value: isAnimating
						)
				}
			}
			.padding()
		}
	}
	
	// Methods
	private func loadScores() {
		scores = scoreManager.getAllScores()
	}
	
	private func clearScores() {
		withAnimation {
			scoreManager.clearScores()
			scores = []
		}
	}
	
	private func animateScores() {
		// Slight delay for visual effect
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			withAnimation {
				isAnimating = true
			}
		}
	}
}

// Score Row View
struct ScoreRowView: View {
	let rank: Int
	let score: GameScore
	let isAnimating: Bool
	
	var body: some View {
		HStack {
			// Rank
			Text("\(rank)")
				.font(.system(size: 18))
				.foregroundColor(rankColor)
				.frame(width: 60, alignment: .center)
			
			// Player name
			Text(score.playerName)
				.font(.system(size: 18))
				.foregroundColor(rankColor)
				.frame(maxWidth: .infinity, alignment: .leading)
			
			// Score
			Text("\(score.score)")
				.font(.system(size: 18))
				.foregroundColor(rankColor)
				.frame(width: 80, alignment: .trailing)
		}
		.padding(.vertical, 12)
		.padding(.horizontal, 15)
		.background(rowBackground)
		.cornerRadius(10)
		.scaleEffect(isAnimating ? 1.0 : 0.8)
		.opacity(isAnimating ? 1.0 : 0)
	}
	
	// Background color based on rank
	private var rowBackground: some View {
		Group {
			switch rank {
//			case 1:
//				Color.orange.opacity(0.5)
			default:
				Color.white.opacity(0.7)
			}
		}
	}
	
	// Text color based on rank
	private var rankColor: Color {
		switch rank {
		case 1:
			return .red
		default:
			return .black
		}
	}
}

#Preview {
	HighScoreView()
}
