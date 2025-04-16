//
//  SettingsView.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.01.
//

import SwiftUI

struct SettingsView: View {
	@State private var countdownInSeconds = 0
	@State private var isCountingDown = false
	@State private var countdownInput = ""
	@State private var bubbleInput = ""
	// Need to change the previous @State to other types
	@State private var countdownValue: Double = 0
	@State private var bubbleValue: Double = 0
	@ObservedObject var settingsViewModel = SettingsViewModel()

	
    var body: some View {
		NavigationView{
			VStack {
				Label("Settings", systemImage: "")
					.font(.title)
					.foregroundColor(.green)
					.padding()
				
				Spacer()
				
				Text("Enter Your Name")
				TextField("Name", text: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Value@*/.constant("")/*@END_MENU_TOKEN@*/)
					.padding()
				
				Text("Game Time")
				Slider(value: $countdownValue, in: 0...60, step:1)
						
			}
			Text("\(Int(countdownValue)) Seconds")
				.padding()
			
			Text("Max Number of Bubbles")
			Slider(value: $bubbleValue, in: 0...15, step:1)
			Text("\(Int(bubbleValue)) ")
				.padding()

			NavigationLink (destination: GameView(), label: {
				Text("Start!")
					.font(.title)
			})
			Spacer()
		}
	}
}


#Preview {
    SettingsView()
}
