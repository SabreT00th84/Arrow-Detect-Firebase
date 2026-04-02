//
//  Archer.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 20/01/2025.
//

import Foundation
import FirebaseFirestore

struct Archer: Codable {
    @DocumentID var archerId: String?
    var userId: String
    var instructorId: String
}
