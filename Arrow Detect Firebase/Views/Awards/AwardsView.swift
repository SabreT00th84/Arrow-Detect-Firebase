//
//  InfoView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 28/12/2024.
//

import SwiftUI

struct AwardsView: View {
    
    @State var viewModel = AwardsViewModel()
    var twoDPFormat = NumberFormatter()
    
    init () {
        twoDPFormat.numberStyle = .percent
    }
    
    var body: some View {
        List {
            ForEach(viewModel.archerAwards, id: \.0.awardId) {(award, awardStatus) in
                NavigationLink (destination: AwardDetailView(awardTuple: (award, awardStatus), archer: viewModel.archer)) {
                    HStack {
                        Text(award.name)
                        ProgressView(value: awardStatus.completionRatio)
                            .progressViewStyle(.linear)
                        Text(twoDPFormat.string(for: awardStatus.completionRatio) ?? "")
                    }
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}

#Preview {
    AwardsView()
}
