//
//  Constants.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/27/24.
//

import Foundation

enum Constants {
    static let immersiveSpaceID = "ImmersiveSpace"
    static let maximumInteractionDistance: Float = 0.5
    static let minimumFingerDistance: Float = 0.005
    // Models created with Object Capture will have a common Entity structure, including
    // an entity named "Mesh".
    // Apple Object Capture sample code for creating USDZs from objects can be found here:
    // https://developer.apple.com/documentation/realitykit/scanning-objects-using-object-capture
    static let objectCaptureMeshName = "Mesh"
    static let swellDefaultAmplitude: Float = 0.01
    static let swellDefaultWindow: Float = 0.05
}
