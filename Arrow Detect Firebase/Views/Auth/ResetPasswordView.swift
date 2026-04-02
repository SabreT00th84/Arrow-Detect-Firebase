//
//  ResetPasswordView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 12/12/2024.
//

import SwiftUI

struct ResetPasswordView: View {
    
    @State var viewModel = ResetPasswordViewModel()
    
    var body: some View {
        ZStack {
            Form {
                Section {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }footer: {
                    VStack {
                        Text(viewModel.message)
                        HStack {
                            Spacer()
                            Button("Send Email") {
                                Task {
                                    await viewModel.SendEmail()
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
            .navigationTitle("Reset Password")
        }
    }
}
    
#Preview {
    ResetPasswordView()
}
