//
//  Requirement.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 11/03/2025.
//

import Foundation
import FirebaseFirestore

struct Requirement: Codable {
    @DocumentID var requirementId: String?
    var awardId: String
    var description: String
    var order: Int
}
