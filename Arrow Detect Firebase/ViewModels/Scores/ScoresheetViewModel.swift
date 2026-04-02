//
//  ScoresheetViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 20/01/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Cloudinary
import simd

@Observable
class ScoresheetViewModel {
    var arrows: [[Arrow?]] = Array(repeating: Array(repeating: nil, count: 3), count: 5)
    var scores: [[String]] = Array(repeating: Array(repeating: "", count: 3), count: 5)
    var images: [CIImage?] = Array(repeating: nil, count: 5)
    var imageIds: [String?] = Array(repeating: nil, count: 5)
    var errorMessage = ""
    var isLoading = false
    var showCameraView = false
    var showImageView = false
    var selectedSize = TargetSize.eighty
    var selectedBow = BowType.barebow
    var selectedDistance = Distance.eighteen
    
    enum TargetSize: Int {
        case eighty = 80
        case sixty = 60
        case forty = 40
    }
    
    enum BowType: String {
        case barebow = "Barebow"
        case recurve = "Recurve"
    }
    
    enum Distance: Int {
        case ten = 10
        case fourteen = 14
        case eighteen = 18
        case twentyFive = 25
        case thirty = 30
    }
    
    private func uploadImage (image: UIImage) async throws -> String {
        guard let data = image.pngData() else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Could not convert image to data"))
        }
        do {
            let publicId = try await withCheckedThrowingContinuation { continuation in
                let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: "duy78o4dc", apiKey: "984745322689627"))
                cloudinary.createUploader().upload(data: data, uploadPreset: "Target-Picture", completionHandler:  { result, error in
                    if let result {
                        continuation.resume(returning: result.publicId)
                    } else if let error {
                        continuation.resume(throwing: error)
                    }
                })}
            return publicId ?? ""
        } catch let error {
            throw error
        }
    }
    
    func intScore (score: String) -> Int {
        if score.uppercased() == "X" {
            return 10
        } else if score.uppercased() == "M"{
            return 0
        } else {
            return Int(score) ?? -1
        }
    }
   
    func createStatsRecord (score: Score, prevScoreId: String?, groupRadii: [Float]) async throws {
        do {
            let db = Firestore.firestore()
            let simplifiedScores = scores.flatMap{$0}.map {$0.uppercased()}
            let intScores = simplifiedScores.map {self.intScore(score: $0)}
            let avgScore = Float(intScores.reduce(0, +))/Float(intScores.count)
            let avgGroupRad = groupRadii.reduce(0, +)/Float(groupRadii.count)
            let perfScore: Float
            let perfImprovement: Float
            
            if avgGroupRad != 0 {
                perfScore = Float(score.scoreTotal)/avgGroupRad
            } else {
                perfScore = Float(score.scoreTotal)
            }
            
            if let prevScoreId, let prevPerf = try await db.collection("Stats").whereField("scoreId", isEqualTo: prevScoreId).getDocuments().documents.first?.data(as: Stat.self).perfScore, prevPerf > 0 {
                perfImprovement = ((perfScore - prevPerf)/prevPerf)
            } else {
                perfImprovement = 0
            }
            
            let statObject =  Stat(scoreId: score.scoreId!,
                                   avgScore: avgScore,
                                   noOfX: simplifiedScores.count {$0 == "X"},
                                   noOf10: simplifiedScores.count {$0 == "10"},
                                   noOf9: simplifiedScores.count {$0 == "9"},
                                   noOf8: simplifiedScores.count {$0 == "8"},
                                   noOf7: simplifiedScores.count {$0 == "7"},
                                   noOf6: simplifiedScores.count {$0 == "6"},
                                   noOf5: simplifiedScores.count {$0 == "5"},
                                   noOf4: simplifiedScores.count {$0 == "4"},
                                   noOf3: simplifiedScores.count {$0 == "3"},
                                   noOf2: simplifiedScores.count {$0 == "2"},
                                   noOf1: simplifiedScores.count {$0 == "1"},
                                   noOfM: simplifiedScores.count {$0 == "M" || $0 == "0"},
                                   avgEndGroupradius: avgGroupRad,
                                   perfScore: perfScore,
                                   perfImprovement: perfImprovement)
            
            try db.collection("Stats").document().setData(from: statObject)
            
        } catch let error {
            throw error
        }
    }
    
    //This function aims to calculate the arrow grouping from an array of 3 points representing the position of arrow tips on the target.
    func calculateGroupRadius (points: [(Float, Float)]) -> Float {
        
        guard points.count == 3 else { //Ensures that the array contains 3 points.
            errorMessage = "3 points are required to calculate the radius" //Updates the error message variable which will be displayed to the user.
            return 0 //Returns 0 if the radius could not be calculated.
        }
        
        let pointsMatrix = simd_float3x3(rows: points.prefix(3).map {simd_float3(2 * $0.0, 2 * $0.1, 1)}) //Creates a circle from the 3 points using matrices.
        let squaredMatrix = simd_float3(points.prefix(3).map {-(pow($0.0, 2) + pow($0.1, 2))}) //Intemediary step solving matrices.
        let solution = pointsMatrix.inverse * squaredMatrix //Solves the matrices and stores an object  the circle centre's x coordinate , y coordinate and a constant.
        
        return sqrt(pow(solution.x, 2) + pow(solution.y, 2) - solution.z) //Calculates the radius from the values in the object using a known maths equation.
    }
    
    func validate() -> Bool {
        let flatArray = scores.flatMap{$0}
        let intArray = flatArray.map{intScore(score: $0)}
        guard flatArray.filter({$0.trimmingCharacters(in: .whitespacesAndNewlines) == "" }).isEmpty else {
            errorMessage = "Please fill in all fields"
            return false
        }
        
        guard !intArray.contains(where: {$0 < 0 || $0 > 10}) else {
            errorMessage = "Please ensure you only enter numbers between 1-10, an X or M"
            return false
        }
        
        return true
    }
    
    @MainActor
    func submit() async -> Bool {
        do {
            let db = Firestore.firestore()
            isLoading = true
            guard validate() else {
                return false
            }
            guard let userId = Auth.auth().currentUser?.uid else {
                errorMessage = "User is not logged in"
                return false
            }
            guard let archerId = try await db.collection("Archers").whereField("userId", isEqualTo: userId).getDocuments().documents.first?.data(as: Archer.self).archerId else {
                errorMessage = "Could not retrive Archer record"
                return false
            }
            
            let scoreDoc = db.collection("Scores").document()
            var scoreTotal = 0
            var groupRadii: [Float] = []
            
            for (x, end) in arrows.enumerated() {
                let endDoc = db.collection("Ends").document()
                let groupRadius: Float
                var publicId = ""
                var endTotal = 0
                var circlePoints: [(Float, Float)] = []
                
                if let image = images[x] {
                    try await publicId = uploadImage(image: UIImage(ciImage: image))
                }
                 
                for (y, arrow) in end.enumerated() {
                    let arrowDoc = db.collection("Arrows").document()
                    let arrowObject: Arrow
                    
                    if scores[x][y] == "0" {
                        scores[x][y] = "M"
                    }
                    
                    if let arrow, arrow.arrowId == arrowDoc.documentID && arrow.endId == endDoc.documentID  {
                        arrowObject = arrow
                    } else if let arrow {
                        arrowObject = Arrow(endId: endDoc.documentID, x: arrow.x, y: arrow.y, score: arrow.score)
                    } else {
                        arrowObject = Arrow(endId: endDoc.documentID, x: 0, y: 0, score: scores[x][y])
                    }
                    circlePoints.append((arrowObject.x, arrowObject.y))
                    endTotal += intScore(score: arrowObject.score)
                    try arrowDoc.setData(from: arrowObject)
                }
                
                let endObject = End(scoreId: scoreDoc.documentID, endNo: x, endTotal: endTotal, isVerified: false, imageId: publicId)
                try endDoc.setData(from: endObject)
                scoreTotal += endTotal
                
                if circlePoints[0] == circlePoints[1] || circlePoints [1] == circlePoints[2] || circlePoints[0] == circlePoints[2] {
                    groupRadius = 0
                } else {
                    groupRadius = calculateGroupRadius(points: circlePoints)
                }
                
                groupRadii.append(groupRadius)
            }
            
            let scoreObject = Score(scoreId: scoreDoc.documentID,
                                    archerId: archerId,
                                    date: Date.now,
                                    bowType: selectedBow.rawValue,
                                    targetSize: selectedSize.rawValue,
                                    distance: selectedDistance.rawValue,
                                    scoreTotal: scoreTotal,
                                    instructorComment: "")
            try scoreDoc.setData(from: scoreObject)
            let prevScore = try await db.collection("Scores").whereField("date", isLessThan: scoreObject.date).order(by: "date").getDocuments().documents.first?.data(as: Score.self)
            try await createStatsRecord(score: scoreObject, prevScoreId: prevScore?.scoreId, groupRadii: groupRadii)
            NotificationCenter.default.post(name: Notification.Name("ScoresheetSubmitted"), object: nil, userInfo: ["record": scoreObject])
            return true
        } catch let error {
            errorMessage = error.localizedDescription
            print(error)
            return false
        }
    }
}
