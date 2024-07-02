//
//  ErrorView.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/25/24.
//

import SwiftUI

struct ErrorView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        Text(errorMessage)
            .font(.title)
            .multilineTextAlignment(.center)
    }
    
    @MainActor
    var errorMessage: String {
        if !appModel.allRequiredProvidersAreSupported {
            return "Sorry, this app requires functionality that isn't supported on this platform or device."
        } else if !appModel.allRequiredAuthorizationsAreGranted {
            return "Sorry, this app is missing necessary authorizations. You can change this in the Privacy & Security settings."
        } else {
            return "Unknown error"
        }
    }
}
