//
//  AwardDetailViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 10/03/2025.
//

import Foundation
import FirebaseFirestore

@Observable
class AwardDetailViewModel {
    var awardTuple: (Award, AwardStatus)
    let archer: Archer?
    var requirementsTuple: [(Requirement, RequirementStatus)] = []
    var qualifyingScore: Score?
    
    @ObservationIgnored var verification: String {
        if awardTuple.1.isVerified {
            return "✅"
        } else {
            return "❌"
        }
    }
    
    private func updateCompletion () {
        do {
            let db = Firestore.firestore()
            let status = requirementsTuple.map {$0.1}
            let noCompleted = status.filter {$0.isCompleted}
            let completionRatio = Float(noCompleted.count)/Float(awardTuple.0.noOfRequirements)
            var awardStatus = awardTuple.1
            awardStatus.completionRatio = completionRatio
            
            try db.collection("AwardStatus").document(awardStatus.awardStatusId!).setData(from: awardStatus, merge: true)
            awardTuple = (awardTuple.0, awardStatus)
        }catch let error {
            print(error)
        }
    }
    
    func toggleStatus(tuple: (Requirement, RequirementStatus)) {
        do {
            let db = Firestore.firestore()
            var isCompleted = tuple.1.isCompleted
            isCompleted.toggle()
            let newStatus = RequirementStatus(requirementStatusId: tuple.1.requirementStatusId!, archerId: tuple.1.archerId, requirementId: tuple.1.requirementId, isCompleted: isCompleted)
            try db.collection("RequirementsStatus").document(tuple.1.requirementStatusId!).setData(from: newStatus, merge: true)
            let index = requirementsTuple.firstIndex(where: {$0.0.requirementId == tuple.0.requirementId})
            requirementsTuple.remove(at: index!)
            requirementsTuple.insert((tuple.0, newStatus), at: index!)
            updateCompletion()
        }catch let error {
            print(error)
        }
    }
    
    @MainActor
    func loadData() async {
        do {
            let db = Firestore.firestore()
            guard let archer = archer, let archerId = archer.archerId else {
                print("Could not retrieve archer record")
                return
            }
            let requirements = try await db.collection("Requirements").whereField("awardId", isEqualTo: awardTuple.0.awardId!).getDocuments().documents.map {try $0.data(as: Requirement.self)}
            print(requirements.count)
            let tupleArray = try await loadRequirementStatus(archerId: archerId, requirements: requirements)
            
            requirementsTuple = tupleArray
            try await loadQualifyingScore()
            
            if qualifyingScore != nil, let tuple = requirementsTuple.first, !tuple.1.isCompleted {
                toggleStatus(tuple: tuple)
            }
            
        }catch let error {
            print(error)
        }
    }
    
    func loadRequirementStatus(archerId: String, requirements: [Requirement]) async throws -> [(Requirement, RequirementStatus)] {
        do {
            let db = Firestore.firestore()
            let requirementIds: [[String]] = requirements.map(\.requirementId!).chunked(into: 30)
            
            var status: [RequirementStatus] = []
            for chunk in requirementIds {
                let result = try await db.collection("RequirementsStatus").whereField("archerId", isEqualTo: archerId).whereField("requirementId", in: chunk).getDocuments().documents.map {try $0.data(as: RequirementStatus.self)}
                status.append(contentsOf: result)
            }
           if status.count == 0 {
                for requirement in requirements {
                    let statusObject = RequirementStatus(archerId: archerId, requirementId: requirement.requirementId!, isCompleted: false)
                    let result = try db.collection("RequirementsStatus").addDocument(from: statusObject)
                    let requirementStatus = try await result.getDocument(as: RequirementStatus.self)
                    status.append(requirementStatus)
                }
            }
            
            var tempArcherRequirements: [(Requirement, RequirementStatus)] = []
            for requirementStatus in status {
                let tuple = (requirements.first(where: {$0.requirementId == requirementStatus.requirementId})!, requirementStatus)
                tempArcherRequirements.append(tuple)
            }
            
            print(tempArcherRequirements.count)
            return tempArcherRequirements.sorted(by: {$0.0.order < $1.0.order})
        } catch let error {
            throw error
        }
    }
    
    private func loadQualifyingScore() async throws{
        do {
            let db = Firestore.firestore()
            let scores = try await db.collection("Scores").whereField("archerId", isEqualTo: awardTuple.1.archerId).whereField("targetSize", isLessThanOrEqualTo: awardTuple.0.maximumTargetSize).whereField("distance", isGreaterThanOrEqualTo: awardTuple.0.minimumDistance).getDocuments().documents.map({try $0.data(as: Score.self)})
            
            var qualifyingScores: [Score] = []
            for score in scores {
                let minimumScore = try minimumScore(score: score)
                if score.scoreTotal >= minimumScore {
                    qualifyingScores.append(score)
                }
            }
            qualifyingScores = qualifyingScores.sorted(by: {$0.scoreTotal > $1.scoreTotal})
            qualifyingScore = qualifyingScores.first
            
        } catch let error {
            throw error
        }
    }
    
    private func minimumScore(score: Score) throws -> Int {
        let bowType = score.bowType
        if bowType == "Barebow" {
            return 86
        } else if bowType == "Recurve" {
            return 115
        } else {
            throw NSError(domain: "minimumScore()", code: -1, userInfo: ["description": "Could not calculate minimum score for score \(score.scoreId ?? "")"])
        }
    }
    
    init(awardTuple: (Award, AwardStatus), archer: Archer?) {
        self.awardTuple = awardTuple
        self.archer = archer
    }
}
