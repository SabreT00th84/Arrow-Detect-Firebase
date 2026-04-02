//
//  IdentifiableData.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 08/03/2025.
//

import Foundation

struct ScoreTableRow: Identifiable {
    let id = UUID()
    let endNo: String
    let arrow1: String
    let arrow2: String
    let arrow3: String
    let endTotal: String
}
