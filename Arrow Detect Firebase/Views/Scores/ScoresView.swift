//
//  ContentView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 13/10/2024.
//

import SwiftUI

struct ScoresView: View {
    @State private var viewModel = ScoresViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.scores, id: \.scoreId) { score in
                NavigationLink {
                    StatsView(score: score)
                } label: {
                    Text(score.date.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .onDelete(perform: viewModel.deleteScores)
        }
        .task {
            await viewModel.loadScores()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ScoresheetSubmitted"))) { notification in
            Task {@MainActor in
                if let object = notification.userInfo?["record"] as? Score {
                    withAnimation {
                        viewModel.scores.append(object)
                    }
                }else {
                    await viewModel.loadScores()
                }
            }
        }
    }
}

#Preview {
    ScoresView()
}
