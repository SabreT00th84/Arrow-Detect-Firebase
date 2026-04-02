//
//  ScoreSheetView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 20/01/2025.
//

import SwiftUI

struct ScoresheetView: View {
    
    @Environment(\.dismiss) var dismiss
    @State var viewModel =  ScoresheetViewModel()
    @State var camera = CameraViewModel()
    
    var body: some View {
        ZStack {
            Form {
                Picker("Target Size", selection: $viewModel.selectedSize) {
                    Text("80cm").tag(ScoresheetViewModel.TargetSize.eighty)
                    Text("60cm").tag(ScoresheetViewModel.TargetSize.sixty)
                    Text("40cm")
                        .tag(ScoresheetViewModel.TargetSize.forty)
                }
                
                Picker("Bow Type", selection: $viewModel.selectedBow) {
                    Text("Barebow").tag(ScoresheetViewModel.BowType.barebow)
                    Text("Recurve").tag(ScoresheetViewModel.BowType.recurve)
                }
                
                Picker("Distance", selection: $viewModel.selectedDistance) {
                    Text("10m").tag(ScoresheetViewModel.Distance.ten)
                    Text("14m").tag(ScoresheetViewModel.Distance.fourteen)
                    Text("18m").tag(ScoresheetViewModel.Distance.eighteen)
                    Text("25m").tag(ScoresheetViewModel.Distance.twentyFive)
                    Text("30m").tag(ScoresheetViewModel.Distance.thirty)
                }
                
                ForEach (0..<5) { endIndex in
                    Section {
                        arrowsView(endIndex: endIndex)
                        button
                    } header: {
                        Text("End \(endIndex + 1)")
                    } footer: {
                        VStack(alignment: .leading) {
                            Text("Automatic detection is still in development")
                            if endIndex == 4 {
                                Text(viewModel.errorMessage)
                                HStack {
                                    Spacer()
                                    Button("Submit") {
                                        Task {
                                            let result = await viewModel.submit()
                                            viewModel.isLoading = false
                                            if result {
                                                dismiss()
                                            }
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            }
        }
        /*.fullScreenCover(isPresented: $viewModel.showCameraView) {
            if let image = camera.image {
                ImageDisplayView(image: image, targetSize: viewModel.selectedSize)
            } else {
                CameraView(viewModel: $camera)
            }
        }*/
    }
    
    @ViewBuilder
    func arrowsView(endIndex: Int) -> some View {
        HStack {
            ForEach (0..<3) { arrowIndex in
                TextField("Arrow \(arrowIndex + 1)", text: $viewModel.scores[endIndex][arrowIndex])
                    .keyboardType(.numbersAndPunctuation)
            }
        }
    }
    
    @ViewBuilder
    var button: some View {
        Button("Scan", systemImage: "camera.viewfinder") {
            viewModel.showCameraView = true
        }
        .disabled(true)
    }
}

#Preview {
    ScoresheetView()
}
