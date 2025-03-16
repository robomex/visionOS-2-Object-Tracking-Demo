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
        
        WindowGroup(id: "uses") {
            Group {
                Text("Use Cases")
                    .font(.title)
                
                Text("""
1. Instructions
2. Tutorials
3. Guided Work
4. Assembly
5. Construction
6. Recipes
7. Compliance
8. Learning
9. Training
10. Upskilling
11. Simulating
12. Accessibility
""")
                .font(.headline)
            }
            .padding()
        }
        
        WindowGroup(id: "actions") {
            Group {
                Text("Behaviors")
                    .font(.title)
                
                Text("""
A. Visual highlights
B. Play a video
C. Play a spatial 3D animation
D. Play some audio
E. Teleport me to a different 3D world
F. Bring up a reference guide for what I'm looking at
G. List the most common failures and issues related to what I'm looking at
H... A million other things
""")
                .font(.headline)
            }
            .padding()
        }

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
