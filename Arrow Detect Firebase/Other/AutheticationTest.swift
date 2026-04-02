//
//  AutheticationTest.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 26/12/2024.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

class AuthenticationTest: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    private var handler: AuthStateDidChangeListenerHandle?
    
    init () {
        self.handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }
    
    public var isSignedInAndVerified: Bool {
        guard let user = Auth.auth().currentUser else { return false }
        user.reload { _ in }
        let isSignedIn = Auth.auth().currentUser != nil
        let isVerified = Auth.auth().currentUser?.isEmailVerified ?? false
        if isSignedIn && isVerified {
            return true
        } else {
            return false
        }
    }
}
