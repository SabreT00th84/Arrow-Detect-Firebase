//
//  ResetPasswordViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 26/12/2024.
//

import FirebaseAuth
import Foundation

@Observable
class ResetPasswordViewModel {
    var email: String = ""
    var message: String = ""
    var isLoading = false
    
    func SendEmail () async {
        do {
            isLoading = true
            guard NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: email) else {
                message = "Please enter a valid email."
                return
            }
            try await Auth.auth().sendPasswordReset(withEmail: email)
            message = "An email has been sent to your email address if you have an account with us. Please check your inbox."
        }catch let error {
            message = error.localizedDescription
        }
    }
}
