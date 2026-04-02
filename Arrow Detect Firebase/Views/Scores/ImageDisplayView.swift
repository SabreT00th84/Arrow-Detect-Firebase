//
//  ImageDisplayView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 27/01/2025.
//

import SwiftUI

struct ImageDisplayView: View {
    
    let image: CIImage
    let targetSize: ScoresheetViewModel.TargetSize
    @State var viewModel: ImageDisplayViewModel
    
    
    var body: some View {
        ZStack (alignment: .bottom) {
            if let cgImage = CIContext().createCGImage(viewModel.image, from: viewModel.image.extent) {
                Image(cgImage, scale: 1, label: Text("Target Image"))
                    .resizable()
                    .scaledToFit()
                Button("Score") {
                    Task {
                        await viewModel.process()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 50)
            }
        }
    }
    
    init (image: CIImage, targetSize: ScoresheetViewModel.TargetSize) {
        self.image = image
        self.targetSize = targetSize
        self.viewModel = ImageDisplayViewModel(image: image, targetSize: targetSize)
    }
}

/*#Preview {
    ImageDisplayView()
}*/
