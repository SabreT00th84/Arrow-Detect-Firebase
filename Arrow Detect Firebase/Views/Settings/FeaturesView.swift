//
//  FeaturesView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 20/01/2025.
//

import SwiftUI

struct FeaturesView: View {
    
    @AppStorage("Leaderboard") var leaderboards = true
    
    var body: some View {
        Form {
            Toggle(isOn: $leaderboards, label: {Label("Leaderboards", systemImage: "trophy")})
            //Toggle(isOn: $caching, label: {Label("Local Caching", systemImage: "gauge.with.dots.needle.67percent")})
        }
        .navigationTitle("Features")
    }
}

#Preview {
    FeaturesView()
}
