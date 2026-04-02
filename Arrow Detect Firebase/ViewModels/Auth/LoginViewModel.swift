//
//  LoginViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 26/12/2024.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

@Observable
class LoginViewModel {
    var email = ""
    var password = ""
    var errorMessage = ""
    var noAccount = false
    var showSignUp = false
    var isLoading = false
    @AppStorage("Instructor") @ObservationIgnored var isInstructor: Bool?
    
    func Login () async {
        do {
            guard Validate() else {
                return
            }
            isLoading = true
            try await Auth.auth().signIn(withEmail: email, password: password)
            guard let authUser = Auth.auth().currentUser else {
                errorMessage = "Failed to log in"
                return
            }
            
            guard authUser.isEmailVerified else {
                try await authUser.sendEmailVerification()
                errorMessage = "Please verify your email address. A verification email has been sent to your inbox."
                return
            }
            
            let user = try await Firestore.firestore().collection("Users").document(authUser.uid).getDocument(as: User.self)
            isInstructor = user.isInstructor
            try await updateDatabaseEmail(document: user, authUser: authUser)
        }catch let error {
            print(error)
            if error.localizedDescription.contains("auth credential is malformed or has expired") {
                errorMessage = "Please check you have an account with us and that your email address and password is correct"
            }else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func Validate () -> Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please fill in all fields."
            return false
        }
        guard NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: email) else {
            errorMessage = "Please enter a valid email."
            return false
        }
        return true
    }
    
    private func updateDatabaseEmail (document: User, authUser: FirebaseAuth.User) async throws {
        do {
            let db = Firestore.firestore()
            if authUser.email != document.email {
                var newUser = document
                newUser.email = authUser.email!
                try db.collection("Users").document(authUser.uid).setData(from: newUser, merge: true)
            }
        }catch {
            throw error
        }
    }
}
