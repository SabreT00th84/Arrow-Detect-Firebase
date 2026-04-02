//
//  CameraViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 21/01/2025.
//

import Foundation
import PhotosUI
import SwiftUI
import AVFoundation

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    
    let completion: (Result<Data, Error>) -> Void
    
    init(completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("Error processing photo: \(error.localizedDescription)")
            completion(.failure(error))
            return
        } else if let photoData = photo.fileDataRepresentation() {
            completion(.success(photoData))
        } else {
            completion(.failure(NSError(domain: "photoOutput()", code: -1, userInfo: ["localizedDescription": "Could not get image data"])))
        }
    }
}

@Observable
class CameraViewModel {
    
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    var imageItem: PhotosPickerItem?
    var photoData: Data?
    var image: CIImage?
    
    private var delegate: PhotoCaptureDelegate?

    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    init () {
        setupCaptureSession()
    }
    
    private func setupCaptureSession () {
        captureSession.beginConfiguration()
        guard let videoDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice), captureSession.canAddInput(videoDeviceInput) else { return }
        if captureSession.inputs.isEmpty {
            captureSession.addInput(videoDeviceInput)
        }
        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.sessionPreset = .photo
        captureSession.addOutput(photoOutput)
        captureSession.commitConfiguration()
    }
    
    @CameraActor
    func startCapture () async {
        guard await isAuthorized,
        captureSession.isRunning == false,
        captureSession.inputs.count > 0
        else { return }
            captureSession.startRunning()
    }
    
    @CameraActor
    func captureImage () async throws -> Data {
        var photoSettings = AVCapturePhotoSettings()
        if photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        }
        photoSettings.photoQualityPrioritization = .balanced
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = PhotoCaptureDelegate { result in
                switch result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            self.delegate = delegate
            photoOutput.capturePhoto(with: photoSettings, delegate: delegate)
        }
    }
    
    @CameraActor
    func getImage () async {
        do {
            photoData = try await captureImage()
            delegate = nil
            guard let data = photoData else {
                print("no data")
                return
            }
            image = convertImage(data: data)
        } catch let error {
            print(error)
            return
        }
    }
    
    func convertImage(data: Data) -> CIImage? {
        guard let ciImage = CIImage(data: data) else {
            print("Could not create CIImage")
            return nil
        }
        return ciImage.oriented(.right)
    }
    
    func stopCapture () {
        guard captureSession.isRunning else { return }
        captureSession.stopRunning()
    }
}
