//
//  AwardStatus.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 10/03/2025.
//

import Foundation
import FirebaseFirestore

struct AwardStatus: Codable {
    @DocumentID var awardStatusId: String?
    var archerId: String
    var awardId: String
    var completionRatio: Float
    var isVerified: Bool
    @ExplicitNull var dateCompleted: Date?
}
