//
//  ObjectTrackingApp.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/24/24.
//

import SwiftUI

@main
struct ObjectTrackingApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appModel)
                .frame(width: 400,
                       height: 500)
                .task {
                    if appModel.allRequiredProvidersAreSupported {
                        await appModel.referenceObjectLoader.loadReferenceObjects()
                    }
                }
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: Constants.immersiveSpaceID) {
            ObjectTrackingRealityView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), 
                        in: .mixed)
     }
}
