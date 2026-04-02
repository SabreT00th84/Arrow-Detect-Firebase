//
//  End.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 06/03/2025.
//

import Foundation
import FirebaseFirestore

struct End: Codable {
    @DocumentID var endId: String?
    var scoreId: String
    var endNo: Int
    var endTotal: Int
    var isVerified: Bool
    var imageId: String
}
