//
//  ProfileEditViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 01/01/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import Cloudinary

@Observable
class ProfileEditViewModel {
    var user: User
    var email = ""
    var name = ""
    var password = ""
    var errorMessage: String = ""
    var isLoading = false
    var profileItem: PhotosPickerItem?
    var profileImage: Data?
    var showEmailChangeAlert = false
    private let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "duy78o4dc", apiKey: "984745322689627", secure: true))
    
    init (givenUser: User) {
        self.user = givenUser
        email = user.email
        name = user.name
    }
    
    private func Validate () -> Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please fill in all fields."
            return false
        }
        guard NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: email) else {
            errorMessage = "Please enter a valid email."
            return false
        }
        return true
    }
    
    func submit () async {
        do {
            guard Validate()  else { return }
            isLoading = true
            guard let authUser = Auth.auth().currentUser else { return}
            let db = Firestore.firestore()
            let reference = db.collection("Users").document(authUser.uid)
            var hasChanged = false
            var nameChanged = false
            if email != user.email {
                showEmailChangeAlert = true
            }
            if name != user.name {
                user.name = name
                hasChanged = true
                nameChanged = true
            }
            
            if profileImage != nil {
                do {
                    let publicId = try await uploadImage(image: UIImage(data: profileImage!)!)
                    user.imageId = publicId
                    hasChanged = true
                } catch let error {
                    print("error uploading new public Id to database")
                    print(error)
                }
            }
            
            if hasChanged {
                try reference.setData(from: user, merge: true)
            }
            
            if nameChanged {
                let request = Auth.auth().currentUser?.createProfileChangeRequest()
                request?.displayName = name
                try await request?.commitChanges()
            }
            
        } catch let error {
            print(error)
        }
    }
    
    func chnageEmail () async {
        do {
            let credential = EmailAuthProvider.credential(withEmail: user.email, password: password)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            errorMessage = "Please check your inbox for a verification email."
            try await Auth.auth().currentUser?.sendEmailVerification(beforeUpdatingEmail: email)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                do {
                    try Auth.auth().signOut()
                }catch {
                    fatalError("Couldn't log out")
                }
            }
        }catch let error {
            print(error)
            errorMessage = error.localizedDescription
        }
    }
    
    private func uploadImage (image: UIImage) async throws -> String {
        guard let data = image.pngData() else { return ""}
        if user.imageId != "" {
            do {
                let (signature, timestamp) = try await generateSignature(publicId: user.imageId, folder: "profile-pictures")
                try await deleteImage(publicId: user.imageId,  folder: "profile-pictures", signature: signature, timestamp: timestamp)
            } catch let error {
                print("error occured deleting old profile picture")
                throw error
            }
        }
        do {
            return try await withCheckedThrowingContinuation { continuation in
                cloudinary.createUploader().upload(data: data, uploadPreset: "Profile-Picture", completionHandler:  { result, error in
                    if let result, let publicId = result.publicId {
                        continuation.resume(returning: publicId)
                    } else if let error {
                        continuation.resume(throwing: error)
                    }
                    self.isLoading = false
                })}
        } catch let error {
            print("Error upploading new image")
            throw error
        }
    }
    
    private func generateSignature(publicId: String, folder: String) async throws -> (String, Int) {
        guard let appUrl = URL(string: "https://railway-cloudinary-production.up.railway.app/generate-destroy-signature/?publicId=\(publicId)") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: appUrl)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        do {
            let jsonData = try JSONDecoder().decode(RailwayResponse.self, from: data)
            return (jsonData.signature, jsonData.timestamp)
        } catch {
            throw URLError(.cannotParseResponse)
        }
    }
    
    private func deleteImage(publicId: String, folder: String, signature: String, timestamp: Int) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let params = CLDDestroyRequestParams().setSignature(CLDSignature(signature: signature, timestamp: NSNumber(value: timestamp))).setInvalidate(true)
            cloudinary.createManagementApi().destroy(publicId, params: params, completionHandler: { result, error in
                if let error {
                    continuation.resume(throwing: error)
                }else {
                    continuation.resume()
                }
            })
        }
    }
}
