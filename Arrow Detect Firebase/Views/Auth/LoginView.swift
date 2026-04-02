//
//  LoginView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 07/12/2024.
//

import SwiftUI

struct LoginView: View {
    
    @State var viewModel = LoginViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section {
                        TextField("Email", text: $viewModel.email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        SecureField("Password", text: $viewModel.password)
                    }footer: {
                        VStack (alignment: .leading){
                            HStack {
                                Spacer()
                                NavigationLink("Forgot Password?", destination: ResetPasswordView())
                                    .padding(.top, 2)
                            }
                            Text(viewModel.errorMessage)
                            HStack {
                                Spacer()
                                NavigationLink("Sign Up", destination: SignUpView())
                                    .buttonStyle(.bordered)
                                Button("Submit") {
                                    Task {
                                        await viewModel.Login()
                                        viewModel.isLoading = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .alert("Sign up?", isPresented: $viewModel.noAccount) {
                                    Button("No") {}
                                    Button("Yes", role: .cancel) {viewModel.showSignUp = true}
                                } message: {
                                    Text("You do not seem to have an account with arrow detect. would you like to sign up?")
                                }
                                Spacer()
                            }
                            .controlSize(.large)
                            .padding(.vertical)
                        }
                    }
                }
                .navigationTitle("Login")
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(2)
                }
            }
            .scrollDisabled(true)
            .navigationDestination(isPresented: $viewModel.showSignUp, destination: {SignUpView()})
        }
    }
}
#Preview {
    LoginView()
}
