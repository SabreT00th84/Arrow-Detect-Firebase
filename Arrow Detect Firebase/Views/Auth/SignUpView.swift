//
//  SignUpView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 12/12/2024.
//

import SwiftUI
import PhotosUI

struct SignUpView: View {
    
    @State var profileItem: PhotosPickerItem?
    @State var viewModel = SignUpViewModel()
    
    var body: some View {
        ZStack {
            Form {
                Section {
                    PhotosPicker("Profile Picture", selection: $profileItem, matching: .images)
                    TextField("Full Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $viewModel.password)
                    SecureField("Confirm", text: $viewModel.confirm)
                    Picker("Role", selection: $viewModel.role) {
                        Text("Archer").tag(SignUpViewModel.Roles.archer)
                        Text("Instructor").tag(SignUpViewModel.Roles.instructor)
                    }
                }footer: {
                    VStack (alignment: .leading) {
                        Text(viewModel.message)
                        HStack {
                            Spacer()
                            Button("Submit") {
                                Task {
                                    await viewModel.SignUp()
                                    viewModel.isLoading = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            Spacer()
                        }
                    }
                }
            }
            .onChange(of: profileItem) {
                Task {
                    viewModel.profileImage = try? await profileItem?.loadTransferable(type: Data.self)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
            }
        }
        .scrollDisabled(true)
        .navigationTitle("Sign-Up")
    }
}

#Preview {
    SignUpView()
}
