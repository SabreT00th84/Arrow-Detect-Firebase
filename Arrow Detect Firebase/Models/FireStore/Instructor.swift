//
//  Instructor.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 20/01/2025.
//

import Foundation
import FirebaseFirestore

struct Instructor: Codable {
    @DocumentID var instructorId: String?
    var userId: String
}
