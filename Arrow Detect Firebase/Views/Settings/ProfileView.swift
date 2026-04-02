//
//  ProfileView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 28/12/2024.
//

import SwiftUI

struct ProfileView: View {
    
    @State var viewModel = ProfileViewModel()
    @State var path = NavigationPath()
    
    var body: some View {
            List {
                if let user = viewModel.user {
                    Section {
                        NavigationLink (destination: {ProfileEditView(givenUser: user)}) {
                            HStack {
                                AsyncImage(url: URL(string: viewModel.imageUrl)) { image in
                                    image.resizable()
                                } placeholder : {
                                    Image(systemName: "person.circle")
                                        .resizable()
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(.circle)
                                VStack (alignment: .leading) {
                                    Text(user.name)
                                    Text(user.email)
                                }
                            }
                        }
                        .navigationTitle("Profile")
                        if let instructorId = viewModel.instructor?.instructorId, user.isInstructor {
                            Text("**InstructorId:** \(instructorId)")
                                .textSelection(.enabled)
                        }
                        Text("**Joined:** \(user.joinDate.formatted(date: .complete, time: .omitted))")
                    }footer: {
                        VStack {
                            HStack {
                                Spacer()
                                NavigationLink("Reset Password") {ResetPasswordView()}
                                    .tint(Color.orange)
                                Button("Log Out") {viewModel.logOut()}
                                    .tint(Color.red)
                                Spacer()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .padding(.vertical)
                            Button("Delete Account") {viewModel.showDeletionAlert = true}
                                .tint(Color.red)
                                .alert("Delete account?", isPresented: $viewModel.showDeletionAlert) {
                                    SecureField("Password", text: $viewModel.password)
                                    Button("Yes", role: .destructive) {
                                        Task {
                                            await viewModel.reathenticateBeforeDeletion()
                                        }
                                    }
                                }message: {
                                    Text("Are you sure you want to delete your account? This is irreversible and will delete all data associated with the account permanently.\n\nPlease enter your password to continue.")
                                }
                        }
                    }
                }else {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
            }
            .task {
                await viewModel.loadData()
                viewModel.generateImageUrl()
            }
    }
}

#Preview {
    ProfileView()
}
