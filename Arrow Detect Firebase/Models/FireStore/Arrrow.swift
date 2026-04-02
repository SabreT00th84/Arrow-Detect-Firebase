//
//  Arrrow.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 27/01/2025.
//

import Foundation
import FirebaseFirestore

struct Arrow: Codable {
    @DocumentID var arrowId: String?
    var endId: String
    var x: Float
    var y: Float
    var score: String
    
}
