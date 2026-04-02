//
//  User.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 26/12/2024.
//

import Foundation
import FirebaseFirestore

struct User: Codable  {
    @DocumentID var userId: String?
    var name: String
    var email: String
    var joinDate: Date
    var isInstructor: Bool
    var imageId: String
}
