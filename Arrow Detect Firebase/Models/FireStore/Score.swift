//
//  Score.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 06/03/2025.
//

import Foundation
import FirebaseFirestore

struct Score: Codable, Equatable, Hashable {
    @DocumentID var scoreId: String?
    var archerId: String
    var date: Date
    var bowType: String
    var targetSize: Int
    var distance: Int
    var scoreTotal: Int
    var instructorComment: String
}
