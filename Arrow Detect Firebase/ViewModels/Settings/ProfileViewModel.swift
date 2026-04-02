//
//  ProfileViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 28/12/2024.
//

import FirebaseAuth
import FirebaseFirestore
import Cloudinary
import Foundation

@Observable
class ProfileViewModel {

    var user: User?
    var instructor: Instructor?
    var showDeletionAlert = false
    var imageUrl = ""
    var password = ""
    
    func loadData () async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Could not find current user")
            return
        }
        
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("Users").document(userId).getDocument()
            let instructor = try await db.collection("Instructors").whereField("userId", isEqualTo: userId).getDocuments().documents.first
            
            if let instructor, instructor.exists {
                try DispatchQueue.main.sync {
                    self.instructor = try instructor.data(as: Instructor.self)
                }
            }
            
            try DispatchQueue.main.sync {
                self.user = try snapshot.data(as: User.self)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func logOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func deleteAccount () async throws {
        do {
            guard let user else {
                print("User has not been initialised")
                return
            }

            let db = Firestore.firestore()
            if let instructor {
                let clubArchers = try await db.collection("Archers").whereField("instructorId", isEqualTo: instructor.instructorId!).getDocuments().documents.map {try $0.data(as: Archer.self)}
                
                for archer in clubArchers {
                    var newObject = archer
                    newObject.instructorId = ""
                    try db.collection("Archers").document(archer.archerId!).setData(from: newObject, merge: true)
                }
                
                try await db.collection("Instructors").document(instructor.instructorId!).delete()
                try await db.collection("Users").document(user.userId!).delete()
                
            }else {
                let archerId = try await db.collection("Archers").whereField("userId", isEqualTo: user.userId!).getDocuments().documents.first!.documentID
                let scoreIds = try await db.collection("Scores").whereField("archerId", isEqualTo: archerId).getDocuments().documents.map(\.documentID)
                let awardStatusIds = try await db.collection("AwardStatus").whereField("archerId", isEqualTo: archerId).getDocuments().documents.map(\.documentID)
                let requirementStatusIds = try await db.collection("RequirementStatus").whereField( "archerId", isEqualTo: archerId).getDocuments().documents.map(\.documentID)
                
                for scoresChunk in scoreIds.chunked(into: 30) {
                    let endIds = try await db.collection("Ends").whereField("scoreId", in: scoresChunk).getDocuments().documents.map(\.documentID)
                    let statIds = try await db.collection("Stats").whereField("scoreid", in: scoresChunk).getDocuments().documents.map(\.documentID)
                    
                    for endChunk in endIds.chunked(into: 30) {
                        let arrowIds = try await db.collection("Arrows").whereField("endId", in: endChunk).getDocuments().documents.map(\.documentID)
                        
                        for arrowId in arrowIds {
                            try await db.collection("Arrows").document(arrowId).delete()
                        }
                    }
                    
                    for endId in endIds {
                        try await db.collection( "Ends").document(endId).delete()
                    }
                    
                    for statId in statIds {
                        try await db.collection("Stats").document(statId).delete()
                    }
                }
                
                for scoreId in scoreIds {
                    try await db.collection("Scores").document(scoreId).delete()
                }
                
                for awardStatusId in awardStatusIds {
                    try await db.collection("AwardStatus").document(awardStatusId).delete()
                }
                
                for requirementStatusId in requirementStatusIds {
                    try await db.collection("RequirementStatus").document(requirementStatusId).delete()
                }
                try await db.collection("Archers").document(archerId).delete()
                try await db.collection("Users").document(user.userId!).delete()
            }
            
            try await Auth.auth().currentUser?.delete()
            
        }catch let error {
            throw error
        }
    }
    
    func reathenticateBeforeDeletion() async {
        do {
            guard let user else {
                print("User not initialised")
                return
            }
            let credential = EmailAuthProvider.credential(withEmail: user.email, password: password)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            try await deleteAccount()
        }catch let error {
            print(error)
        }
    }
    
    func generateImageUrl() {
        guard let user else {
            print("User has not been initialised")
            return
        }
        
        let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "duy78o4dc", apiKey: "984745322689627", secure: true))
        guard let url = cloudinary.createUrl().setTransformation(CLDTransformation().setGravity("face").setHeight(100).setWidth(100).setCrop("thumb")).generate(user.imageId) else {
            print("error occured generating url")
            return
        }
        self.imageUrl = url
    }
}
