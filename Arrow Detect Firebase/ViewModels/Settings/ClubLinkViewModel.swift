//
//  ClubLinkViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 12/03/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@Observable
class ClubLinkViewModel {
    var instructorId = ""
    var archer: Archer?
    var insUser: User?
    var errorMessage: String?
    var isLoading = false
    var success = false
    var clubLinked: Bool?
    
    @MainActor
    func loadData () async {
        do {
            guard let user = Auth.auth().currentUser else {
                print("user not logged in")
                return
            }
            
            let db = Firestore.firestore()
            archer = try await db.collection("Archers").whereField("userId", isEqualTo: user.uid).getDocuments().documents.first?.data(as: Archer.self)
            
            guard let archer, archer.instructorId != "" else { //Added to make sure the document path is never empty
                clubLinked = false
                print("No club linked")
                return
            }
            
            let insUserId = try await db.collection("Instructors").document(archer.instructorId).getDocument(as: Instructor.self).userId
            insUser = try await db.collection("Users").document(insUserId).getDocument(as: User.self)
            clubLinked = true
        }catch let error {
            errorMessage = error.localizedDescription
        }
    }
    
    func unlink () async {
        do {
            guard var newArcher = archer else {
                print("archer not found")
                return
            }
            let db = Firestore.firestore()
            newArcher.instructorId = ""
            instructorId = ""
            try db.collection("Archers").document(newArcher.archerId!).setData(from: newArcher, merge: true)
            
        }catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func validate () async -> Bool {
        do {
            guard !instructorId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "Please fill in all fields"
                return false
            }
            let db = Firestore.firestore()
            let instructor = try await db.collection("Instructors").document(instructorId).getDocument()
            if instructor.exists { //if statement added because the instructorid was not being verified
                return true
            }else {
                errorMessage = "Instructor not found"
                return false
            }
        }catch let error {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    func submit () async {
        do {
            isLoading = true
            guard await validate() else {return}
            guard let userId = Auth.auth().currentUser?.uid else {
                errorMessage = "User id not logged in"
                return
            }
            let db = Firestore.firestore()
            guard let archer = try await db.collection("Archers").whereField("userId", isEqualTo: userId).getDocuments().documents.first?.data(as: Archer.self) else {
                errorMessage = "Could not retrieve archer record"
                return
            }
            let updatedArcher = Archer(userId: userId, instructorId: instructorId)
            try db.collection("Archers").document(archer.archerId!).setData(from: updatedArcher, merge: true)
            success = true
        }catch let error {
            errorMessage = error.localizedDescription
            return
        }
    }
}
