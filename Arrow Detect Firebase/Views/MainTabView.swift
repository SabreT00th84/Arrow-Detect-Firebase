//
//  MainTabView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 28/12/2024.
//

import SwiftUI

struct MainTabView: View {
    
    @AppStorage("Instructor") var isInstructor: Bool?
    @AppStorage("Leaderboard") var showLeaderboard: Bool?
    
    @State var viewModel = MainTabViewModel()
    @State var path = NavigationPath()
    
    var body: some View {
        NavigationStack (path: $path) {
            TabView (selection: $viewModel.selection){
                Tab(value: 0, content: {ScoresView()}, label: {Label("Scores", systemImage: "chart.bar.xaxis")})
                    .hidden(isInstructor ?? false)
                Tab(value: 1, content: {LeaderboardView()}, label: {Label("Leaderboard", systemImage: "trophy")})
                    .hidden(!(showLeaderboard ?? true))
                Tab(value: 2, content: {AwardsView()}, label: {Label("Awards", systemImage: "medal")})
                    .hidden(isInstructor ?? false)
                Tab(value: 3, content: {MainSettingsView()}, label: {Label("Settings", systemImage: "gearshape")})
            }
            .navigationDestination(isPresented: $viewModel.showScoresheet, destination: {ScoresheetView()})
            .toolbar {
                if viewModel.selection == 0, !(isInstructor ?? false) {
                    ToolbarItem {
                        Button(action: viewModel.addItem) {
                     Label("Add Item", systemImage: "plus")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
