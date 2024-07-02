//
//  HomeView.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/24/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if appModel.canEnterImmersiveSpace {
                VStack {
                    Text("Gourmet Breakfast Recipe")
                        .font(.title)
                    
                    if appModel.immersiveSpaceState == .open {
                        steps
                    }
                    
                    Spacer()
                    
                    ToggleImmersiveSpaceButton()
                }
                .padding()
            } else {
                ErrorView()
            }
        }
        .padding()
        .onChange(of: scenePhase, 
                  initial: true)
        {
            print("HomeView scene phase: \(scenePhase)")
            if scenePhase == .active {
                Task {
                    // When returning from the background, check if the authorization has changed.
                    await appModel.queryWorldSensingAuthorization()
                }
            } else {
                // Make sure to leave the immersive space if this view is no longer active
                // - such as when a person closes this view - otherwise they may be stuck
                // in the immersive space without the controls this view provides.
                if appModel.immersiveSpaceState == .open {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
            }
        }
        .onChange(of: appModel.providersStoppedWithError, { _, providersStoppedWithError in
            // Immediately close the immersive space if an error occurs.
            if providersStoppedWithError {
                if appModel.immersiveSpaceState == .open {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }
                
                appModel.providersStoppedWithError = false
            }
        })
        .task {
            // Ask for authorization before a person attempts to open the immersive space.
            // This gives the app opportunity to respond gracefully if authorization isn't granted.
            if appModel.allRequiredProvidersAreSupported {
                await appModel.requestWorldSensingAuthorization()
            }
        }
        .task {
            // Start monitoring for changes in authorization, in case a person brings the
            // Settings app to the foreground and changes authorizations there.
            await appModel.monitorSessionEvents()
        }
    }
    
    private var steps: some View {
        Group {
            Text("1. Find a container")
            
            Text("2. Find the first ingredient")
                .opacity(appModel.recipeStep != .step1 ? 1 : 0)
            
            Text("3. Find the second ingredient")
                .opacity(appModel.recipeStep == .step3 || appModel.recipeStep == .complete ? 1 : 0)
            
            Text("4. Enjoy!")
                .opacity(appModel.recipeStep == .complete ? 1 : 0)
        }
        .font(.headline)
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    let appModel = AppModel()
    
    HomeView()
        .environment(appModel)
}
