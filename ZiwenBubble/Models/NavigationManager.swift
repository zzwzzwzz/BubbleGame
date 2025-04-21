//
//  NavigationManager.swift
//  ZiwenBubble
//
//  Created by ZZ on 2025.04.21.
//

import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
    @Published var shouldPopToRoot = false
    
    func popToRoot() {
        // Clear navigation path
        path = NavigationPath()
        // Signal we need to pop to root
        shouldPopToRoot = true
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldPopToRoot = false
        }
    }
}