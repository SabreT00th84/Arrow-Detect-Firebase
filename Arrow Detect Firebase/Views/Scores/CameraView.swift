//
//  CameraView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 20/01/2025.
//

import SwiftUI
import PhotosUI
import AVFoundation

class CameraUIView: UIView {
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

struct CameraViewRepresentable: UIViewRepresentable {
    
    let model: CameraViewModel
    
    func makeUIView(context: Context) -> CameraUIView {
        DispatchQueue.main.async {
            Task {
                await model.startCapture()
            }
        }
        let view = CameraUIView()
        view.backgroundColor = .black
        view.previewLayer.session = model.captureSession
        view.previewLayer.videoGravity = .resizeAspect
        view.previewLayer.connection?.videoRotationAngle = 90
        return view
    }
    
    func updateUIView (_ UIView: CameraUIView, context: Context) {}
}


struct CameraView: View {
    
    @Binding var viewModel: CameraViewModel
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CameraViewRepresentable(model: viewModel)
                .ignoresSafeArea()
                HStack (alignment: .center) {
                    PhotosPicker(selection: $viewModel.imageItem, matching: .images, photoLibrary: .shared()) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 70, height: 70, alignment: .leading)
                                .padding()
                        }
                        .onChange(of: viewModel.imageItem) {
                            Task {
                                viewModel.photoData = try? await viewModel.imageItem?.loadTransferable(type: Data.self)
                                guard let data = viewModel.photoData,
                                      let ciImage = CIImage(data: data) else {
                                    print("Could not create ciImage from photoPicker")
                                    return
                                }
                                viewModel.image = ciImage
                            }
                        }
                    Spacer()
                    Button() {
                        Task {
                            await viewModel.getImage()
                        }
                    } label: {
                        Circle()
                            .foregroundStyle(Color.white)
                            .frame(width: 70, height: 70, alignment: .center)
                            .overlay {
                                Circle()
                                    .stroke(Color.black.opacity(0.8), lineWidth: 2)
                                    .frame(width: 59, height: 59, alignment: .center)
                            }
                    }
                    .padding()
                    Spacer(minLength: 135)
                }
                .background(Color.black)
        }
        .onDisappear {
            viewModel.stopCapture()
        }
    }
}

/*#Preview {
    CameraView()
}*/
