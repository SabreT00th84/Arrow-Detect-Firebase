//
//  LeaderboardViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 09/03/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Cloudinary
import SwiftUI

@Observable
class LeaderboardViewModel {
    
    @AppStorage("Instructor") @ObservationIgnored var isinstructor: Bool?
    var topScores: [(User, Score)] = []
    var selectedInterval = 7
    var errorMessage: String?
    
    func generateImageUrl(user: User) -> String {
        let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "duy78o4dc", apiKey: "984745322689627", secure: true))
        guard let url = cloudinary.createUrl().setTransformation(CLDTransformation().setGravity("face").setHeight(100).setWidth(100).setCrop("thumb")).generate(user.imageId) else {
            print("error occured generating url")
            return ""
        }
        return url
    }
    
    func getUser(archerId: String) async throws -> User {
        do {
            let db = Firestore.firestore()
            let archer = try await db.collection("Archers").document(archerId).getDocument(as: Archer.self)
            return try await db.collection("Users").document(archer.userId).getDocument(as: User.self)
        } catch let error {
            throw error
        }
    }
    
    func loadTopScores() async {
        do {
            let db = Firestore.firestore()
            
            guard let timeDifference = Calendar.current.date(byAdding: .day, value: -selectedInterval, to: .now) else {
                errorMessage = "Could not calculate time difference"
                return
            }
            
            guard let userId = Auth.auth().currentUser?.uid else {
                errorMessage = "User is not signed in"
                return
            }
            var instructorId = ""
            if let isinstructor, isinstructor {
                guard let instructor = try await db.collection("Instructors").whereField("userId", isEqualTo: userId).getDocuments().documents.first?.data(as: Instructor.self) else {
                    errorMessage = "Could not retrieve instructor record"
                    return
                }
                instructorId = instructor.instructorId!
            }else {
                guard let archer = try await db.collection("Archers").whereField("userId", isEqualTo: userId).getDocuments().documents.first?.data(as: Archer.self) else {
                    errorMessage = "Could not retrieve archer record"
                    return
                }
                instructorId = archer.instructorId
            }
            
            guard instructorId != "" else {
             errorMessage = "Please join a club before using the leaderboard feature"
             return
             }
            
            let allClubArcherIds = try await db.collection("Archers").whereField("instructorId", isEqualTo: instructorId).getDocuments().documents.map({try $0.data(as: Archer.self).archerId})
            
            guard !allClubArcherIds.isEmpty else {
                errorMessage = "No Archers in this club"
                return
            }
            
            var scores: [Score]
            if selectedInterval == 0 {
                scores = try await db.collection("Scores").whereField("archerId", in: allClubArcherIds as [Any]).getDocuments().documents.map({try $0.data(as: Score.self)})
            }else {
                scores = try await db.collection("Scores").whereField("archerId", in: allClubArcherIds as [Any]).whereField("date", isGreaterThan: timeDifference).getDocuments().documents.map({try $0.data(as: Score.self)})
                }
            let topArcherIds = Set(scores.map(\.archerId))
            var tempScores: [(User, Score)] = []
            for id in topArcherIds {
                let archerScores = scores.filter({$0.archerId == id}).sorted {$0.scoreTotal > $1.scoreTotal}
                guard let firstScore = archerScores.first else {
                    print( "No scores for archer \(id)")
                    continue
                }
                try await tempScores.append((getUser(archerId: id), firstScore))
            }
            let sorted = tempScores.sorted(by: {$0.1.scoreTotal > $1.1.scoreTotal})
            topScores = sorted
        } catch let error {
            print(error)
        }
    }
}
