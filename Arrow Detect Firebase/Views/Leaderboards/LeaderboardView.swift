//
//  LeaderboardView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 28/12/2024.
//

import SwiftUI

struct LeaderboardView: View {
    
    @State var viewModel = LeaderboardViewModel()
    
    var body: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.callout)
                .padding()
                .multilineTextAlignment(.center)
                .onDisappear {
                    viewModel.errorMessage = nil
                }
        } else {
            main
        }
    }
    
    @ViewBuilder
    var main: some View {
        VStack {
            Picker("Interval", selection: $viewModel.selectedInterval) {
                Text("Weekly").tag(7)
                Text("Monthly").tag(30)
                Text("Yearly").tag(365)
                Text("All-Time").tag(0)
            }
            .pickerStyle(.segmented)
            .padding()
            Spacer()
            List {
                loop
            }
        }
        .task {
            await viewModel.loadTopScores()
        }
        .onChange(of: viewModel.selectedInterval) {
            Task {
                await viewModel.loadTopScores()
            }
        }
    }

    @ViewBuilder
    var loop: some View {
        ForEach(viewModel.topScores, id: \.0.userId) {(user, score) in
            HStack {
                Text(String(viewModel.topScores.firstIndex(where: {$0.0.userId == user.userId})! + 1))
                    .font(.headline)
                AsyncImage(url: URL(string: viewModel.generateImageUrl(user: user))) { image in
                    image.resizable()
                } placeholder : {
                    Image(systemName: "person.circle")
                        .resizable()
                }
                .frame(width: 40, height: 40)
                .clipShape(.circle)
                Text("\(user.name)")
                Spacer()
                Text("\(score.scoreTotal)")
            }
        }
    }
}

#Preview {
    LeaderboardView()
}
