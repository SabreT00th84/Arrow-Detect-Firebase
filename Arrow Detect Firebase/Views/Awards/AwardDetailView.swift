//
//  AwardDetailView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 10/03/2025.
//

import SwiftUI

struct AwardDetailView: View {
    
    @State var viewModel: AwardDetailViewModel
    var twoDPFormat = NumberFormatter()
    var percentFormat = NumberFormatter()
    
    var body: some View {
        List {
            Section {
                if let qualifyingScore = viewModel.qualifyingScore {
                    NavigationLink(qualifyingScore.date.formatted(date: .abbreviated, time: .shortened), destination: StatsView(score: qualifyingScore))
                }else {
                    Text("No qualifying score")
                }
            }header: {
                VStack (alignment: .leading){
                    HStack {
                        ProgressView(value: viewModel.awardTuple.1.completionRatio)
                            .progressViewStyle(.linear)
                        Text(percentFormat.string(for: viewModel.awardTuple.1.completionRatio) ?? "")
                    }
                    Text("**Completion:** \(twoDPFormat.string(for: viewModel.awardTuple.1.completionRatio * Float (viewModel.awardTuple.0.noOfRequirements)) ?? "")/\(twoDPFormat.string(for:viewModel.awardTuple.0.noOfRequirements) ?? "")")
                    Text("**Verified:** \(viewModel.verification)")
                    Text("Qualifying Score")
                        .font(.headline)
                }

            }
            Section {
                ForEach (viewModel.requirementsTuple, id: \.0.requirementId) {(requirement, status) in
                    var isPerformance: Bool {
                        if requirement.order == -1 {
                            return true
                        }else {
                            return false
                        }
                    }
                    
                    HStack {
                        Button {
                            viewModel.toggleStatus(tuple: (requirement, status))
                        }label: {
                            Image(systemName: status.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(Color.green)
                        }
                        .disabled(isPerformance)
                        Text(requirement.description)
                    }
                }
            }header: {
                Text("Requirements")
                    .font(.headline)
            }
        }
        .navigationTitle(viewModel.awardTuple.0.name)
        .task {
            await viewModel.loadData()
        }
    }
    
    init (awardTuple: (Award, AwardStatus), archer: Archer?) {
        self.viewModel = AwardDetailViewModel(awardTuple: awardTuple, archer: archer)
        twoDPFormat.numberStyle = .decimal
        twoDPFormat.maximumFractionDigits = 2
        percentFormat.numberStyle = .percent
        percentFormat.maximumFractionDigits = 2
    }
}

/*#Preview {
    AwardDetailView()
}*/
