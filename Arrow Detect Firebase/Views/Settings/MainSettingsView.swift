//
//  SettingsView.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 28/12/2024.
//

import SwiftUI

struct MainSettingsView: View {
    
    @AppStorage("Instructor") var isInstructor: Bool?
    
    var body: some View {
        List {
            NavigationLink (destination: ProfileView(), label: {Label("Profile", systemImage: "person.crop.circle")})
            NavigationLink (destination: ClubLinkView(), label: {Label("Club Link", systemImage: "person.2")})
                .disabled(isInstructor ?? false)
            NavigationLink (destination: FeaturesView(), label: {Label("Features", systemImage: "wand.and.rays")})
        }
    }
}

#Preview {
    MainSettingsView()
}
