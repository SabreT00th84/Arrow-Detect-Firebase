//
//  InfoViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 10/03/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@Observable
class AwardsViewModel {
    
    var archerAwards: [(Award, AwardStatus)] = []
    var archer: Archer?
    
    @MainActor
    func loadData() async {
        do {
            let db = Firestore.firestore()
            var awards = try await db.collection("Awards").getDocuments().documents.map {try $0.data(as: Award.self)}
            awards.sort(by: {$0.order < $1.order})
            guard let userId = Auth.auth().currentUser?.uid else {
                print("User not logged in")
                return
            }
            let archer = try await db.collection("Archers").whereField("userId", isEqualTo: userId).getDocuments().documents.first?.data(as: Archer.self)
            guard let archer, let archerId = archer.archerId else {
                print("Could not retrieve archer record")
                return
            }
            self.archer = archer
            let tempArcherAwards = try await loadAwardStatus(archerId: archerId, awards: awards)
            archerAwards = tempArcherAwards
        } catch let error {
            print(error)
        }
    }
    
    func loadAwardStatus(archerId: String, awards: [Award]) async throws -> [(Award, AwardStatus)] {
        do {
            let db = Firestore.firestore()
            var status = try await db.collection("AwardStatus").whereField("archerId", isEqualTo: archerId).getDocuments().documents.map {try $0.data(as: AwardStatus.self)}
            
            if status.isEmpty {
                for award in awards {
                    let statusObject = AwardStatus(archerId: archerId, awardId: award.awardId!, completionRatio: 0, isVerified: false, dateCompleted: nil)
                    let result = try db.collection("AwardStatus").addDocument(from: statusObject)
                    let awardStatus = try await result.getDocument(as: AwardStatus.self)
                    status.append(awardStatus)
                }
            }
            
            var tempArcherAwards: [(Award, AwardStatus)] = []
            for awardStatus in status {
                let tuple = (awards.first(where: {$0.awardId == awardStatus.awardId})!, awardStatus)
                tempArcherAwards.append(tuple)
            }
            
            return tempArcherAwards.sorted(by: {$0.0.order < $1.0.order})
        } catch let error {
            throw error
        }
    }
}
