//
//  ScoresViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 20/01/2025.
//

import Foundation

@Observable
class MainTabViewModel {
    var showScoresheet = false
    var selection = 0
    
    func addItem () {
        showScoresheet = true
    }
}
