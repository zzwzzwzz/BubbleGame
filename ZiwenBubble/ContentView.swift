//
//  ContentView.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
		NavigationView {
			VStack {
				NavigationLink (destination:
					GameView(), label: {
						Text("New Game")
							.font(.title)
				})
				Spacer()
				NavigationLink (destination:
					HighScoreView(), label: {
						Text("High Score")
							.font(.title)
				})
			}
		}
    }
}

#Preview {
    ContentView()
}
