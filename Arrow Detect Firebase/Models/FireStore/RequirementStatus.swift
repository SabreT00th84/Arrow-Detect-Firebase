//
//  RequirementStatus.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 11/03/2025.
//

import Foundation
import FirebaseFirestore

struct RequirementStatus: Codable {
    @DocumentID var requirementStatusId: String?
    var archerId: String
    var requirementId: String
    var isCompleted: Bool
    @ExplicitNull var dateCompleted: Date?
}
