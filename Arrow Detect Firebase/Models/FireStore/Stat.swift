//
//  Stat.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 06/03/2025.
//

import Foundation
import FirebaseFirestore

struct Stat: Codable {
    @DocumentID var statId: String?
    var scoreId: String
    var avgScore: Float
    var noOfX: Int
    var noOf10: Int
    var noOf9: Int
    var noOf8: Int
    var noOf7: Int
    var noOf6: Int
    var noOf5: Int
    var noOf4: Int
    var noOf3: Int
    var noOf2: Int
    var noOf1: Int
    var noOfM: Int
    var avgEndGroupradius: Float
    var perfScore: Float
    var perfImprovement: Float
}
