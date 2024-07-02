//
//  ObjectTrackingRealityView.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/24/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ObjectTrackingRealityView: View {
    @Environment(AppModel.self) private var appModel
    
    private var rootEntity = Entity()

    var body: some View {
        RealityView { content in
            content.add(rootEntity)
        }
        .task {
            await appModel.startTracking(with: rootEntity)
        }
        .onDisappear() {
            for (_, visualization) in appModel.objectVisualizations {
                rootEntity.removeChild(visualization.entity)
            }
            
            appModel.objectVisualizations.removeAll()
        }
    }
}
