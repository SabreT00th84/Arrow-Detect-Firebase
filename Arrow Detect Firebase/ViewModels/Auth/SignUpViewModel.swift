//
//  SignUpViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 26/12/2024.
//
import Cloudinary
import FirebaseFirestore
import FirebaseAuth
import Foundation
import PhotosUI
import SwiftUI

@Observable
class SignUpViewModel {
    var name = ""
    var email = ""
    var password = ""
    var confirm = ""
    var role = Roles.archer
    var message = ""
    var isLoading = false
    var hasAccount = false
    var profileImage: Data?
    var passwordHidden = true
    @AppStorage("Instructor") @ObservationIgnored var isInstructor: Bool?
    
    enum Roles {
        case archer, instructor
    }
    
    func SignUp () async {
        guard validate() else {
            return
        }
        isLoading = true
        await self.createUserRecord()
    }
    
    
    private func ceateLoginRecord () async -> AuthDataResult? {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let request = Auth.auth().currentUser?.createProfileChangeRequest()
            request?.displayName = name
            try await request?.commitChanges()
            try await Auth.auth().currentUser?.sendEmailVerification()
            message = "Please verify your email address. A verification email has been sent to your inbox."
            return result
        } catch {
            DispatchQueue.main.sync {
                self.message = error.localizedDescription
            }
            return nil
        }
    }
    
    private func createUserRecord () async {
        let publicId: String
        
        if self.profileImage != nil {
            do {
                publicId = try await uploadImage(image: UIImage(data: (self.profileImage!))!)
            } catch {
                DispatchQueue.main.sync {
                    self.message = error.localizedDescription
                }
                return
            }
        } else {
             publicId = ""
        }
        guard let result = await ceateLoginRecord() else {return}
        let userId = result.user.uid
        let newUser = User(name: name, email: email, joinDate: Date.now, isInstructor: role == Roles.instructor, imageId: publicId)
        let db = Firestore.firestore()
        DispatchQueue.main.sync {
            do {
                try db.collection("Users").document(userId).setData(from: newUser)
                if role == Roles.instructor {
                    isInstructor =  true
                    let document = db.collection("Instructors").document()
                    let newInstructor = Instructor(userId: userId)
                    try document.setData(from:newInstructor)
                } else {
                    isInstructor = false
                    let newArcher = Archer(userId: userId, instructorId: "")
                    try db.collection("Archers").document().setData(from: newArcher)
                }
            } catch {
                self.message = error.localizedDescription
            }
            return
        }
    }
    
    private func validate () -> Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !confirm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            message = "Please fill in all fields"
            return false
        }
        guard NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: email) else {
            message = "Please enter a valid email address"
            return false
        }
        guard password == confirm else {
            message = "Please make sure passwords match"
            return false
        }
        return true
    }
    
    private func uploadImage (image: UIImage) async throws -> String {
        guard let data = image.pngData() else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Could not convert image to data"))
        }
        do {
            let publicId = try await withCheckedThrowingContinuation { continuation in
                let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "duy78o4dc", apiKey: "984745322689627"))
                cloudinary.createUploader().upload(data: data, uploadPreset: "Profile-Picture", completionHandler:  { result, error in
                    if let result {
                        continuation.resume(returning: result.publicId)
                    } else if let error {
                        continuation.resume(throwing: error)
                    }
                })}
            return publicId ?? ""
        } catch let error {
            throw error
        }
    }
}
