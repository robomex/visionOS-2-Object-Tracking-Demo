//
//  AppModel.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/24/24.
//

import ARKit
import RealityKit
import UIKit

/// Maintains app-wide state
@MainActor
@Observable
class AppModel {
    enum Grip {
        case both(ModelEntity?)
        case left(ModelEntity?)
        case right(ModelEntity?)
        case none(ModelEntity?)
        
        var color: UIColor {
            switch self {
            case .both: return .green
            case .right: return .magenta
            case .left: return .cyan
            case .none: return .yellow
            }
        }
        
        var model: ModelEntity? {
            switch self {
            case .both(let model), .right(let model), .left(let model), .none(let model):
                return model
            }
        }
    }
    
    enum HandProximity {
        case proximity(HandAnchor.Chirality?, ModelEntity?, Float?)
        case none(HandAnchor.Chirality?, ModelEntity?, Float?)
        
        var chirality: HandAnchor.Chirality {
            switch self {
            case .proximity(let chirality, _, _), .none(let chirality, _, _):
                guard let chirality else {
                    return .left
                }
                
                return chirality
            }
        }
        
        var model: ModelEntity? {
            switch self {
            case .proximity(_, let model, _), .none(_, let model, _):
                return model
            }
        }
        
        var value: Float {
            switch self {
            case .proximity(_, _, let value), .none(_, _, let value):
                guard let value else {
                    return 0.0
                }
                
                return value
            }
        }
    }
    
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    
    enum RecipeStep {
        case step1
        case step2
        case step3
        case complete
    }
    
    var allRequiredAuthorizationsAreGranted: Bool {
        worldSensingAuthorizationStatus == .allowed
    }
    var allRequiredProvidersAreSupported: Bool {
        HandTrackingProvider.isSupported && ObjectTrackingProvider.isSupported
    }
    var canEnterImmersiveSpace: Bool {
        allRequiredAuthorizationsAreGranted && allRequiredProvidersAreSupported
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed {
        didSet {
            guard immersiveSpaceState == .closed else { return }
            
            arkitSession.stop()
            recipeStep = .step1
        }
    }
    var isReadyToRun: Bool {
        handTrackingProvider?.state == .initialized && objectTrackingProvider?.state == .initialized
    }
    
    var objectVisualizations: [UUID: ObjectAnchorVisualization] = [:]
    var providersStoppedWithError = false
    var recipeStep: RecipeStep = .step1
    
    private var arkitSession = ARKitSession()
    private var handTrackingProvider: HandTrackingProvider?
    private var objectTrackingProvider: ObjectTrackingProvider?
    private var worldSensingAuthorizationStatus = ARKitSession.AuthorizationStatus.notDetermined
    
    private var leftHandNearestDistance: Float?
    private var rightHandNearestDistance: Float?
    
    private var boxHandProximity: HandProximity = .none(nil, nil, nil) {
        didSet {
            boxHandProximity.model?.setShaderGraphParameter(for: boxHandProximity.chirality,
                                                            to: boxHandProximity.value)
        }
    }
    private var dutchOvenGrip: Grip = .none(nil) {
        didSet {
            dutchOvenGrip.model?.replaceBaseColor(with: dutchOvenGrip.color)
        }
    }
    
    let referenceObjectLoader = ReferenceObjectLoader()
    
    func monitorSessionEvents() async {
        for await event in arkitSession.events {
            switch event {
            case .dataProviderStateChanged(_, let newState, let error):
                switch newState {
                case .initialized, .running, .paused:
                    break
                case .stopped:
                    if let error {
                        print("An ARKitSession error occurred: \(error)")
                        providersStoppedWithError = true
                    }
                @unknown default:
                    break
                }
            case .authorizationChanged(let type, let status):
                if type == .worldSensing {
                    worldSensingAuthorizationStatus = status
                }
            default:
                print("An unknown ARKitSession event occurred: \(event)")
            }
        }
    }
    
    func queryWorldSensingAuthorization() async {
        let authorizationQuery = await arkitSession.queryAuthorization(for: [.worldSensing])
        
        guard let authorizationResult = authorizationQuery[.worldSensing] else {
            fatalError("Failed to obtain .worldSensing authorization query result")
        }
        
        worldSensingAuthorizationStatus = authorizationResult
    }
    
    func requestWorldSensingAuthorization() async {
        let authorizationRequest = await arkitSession.requestAuthorization(for: [.worldSensing])
        
        guard let authorizationResult = authorizationRequest[.worldSensing] else {
            fatalError("Failed to obtain .worldSensing authorization request result")
        }
        
        worldSensingAuthorizationStatus = authorizationResult
    }
    
    func startTracking(with rootEntity: Entity) async {
        let referenceObjects = referenceObjectLoader.referenceObjects
        
        guard !referenceObjects.isEmpty else {
            fatalError("No reference objects found to start tracking")
        }
        
        let objectTrackingProvider = ObjectTrackingProvider(referenceObjects: referenceObjects)
        let handTrackingProvider = HandTrackingProvider()
        
        do {
            try await arkitSession.run([objectTrackingProvider, handTrackingProvider])
        } catch {
            print("Error running arkitSession: \(error)")
            
            return
        }
        
        self.handTrackingProvider = handTrackingProvider
        self.objectTrackingProvider = objectTrackingProvider
        
        Task {
            await processHandUpdates()
        }
        
        Task {
            await processObjectUpdates(with: rootEntity)
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateAmplitude(for distance: Float) -> Float {
        let speed = (5.0 - (distance / Constants.maximumInteractionDistance) * 4.0) * 0.01
        
        return speed
    }
    
    private func calculateWindow(for distance: Float) -> Float {
        let window = 0.35 - (distance / 0.5) * 0.3
        
        return window
    }
    
    private func processHandUpdates() async {
        guard let handTrackingProvider else {
            print("Error obtaining handTrackingProvider upon processHandUpdates")
            
            return
        }
        
        for await update in handTrackingProvider.anchorUpdates {
            let handAnchor = update.anchor
            
            for (_, visualization) in objectVisualizations {
                guard let modelEntity = visualization.entity.findEntity(named: Constants.objectCaptureMeshName) as? ModelEntity
                else {
                    continue
                }
                
                if let (_, distance) = handAnchor.nearestFingerDistance(to: modelEntity) {
                    if handAnchor.chirality == .left {
                        leftHandNearestDistance = distance
                    } else {
                        rightHandNearestDistance = distance
                    }
                    
                    let leftHandNearestDistance: Float = leftHandNearestDistance ?? Float.infinity
                    let rightHandNearestDistance: Float = rightHandNearestDistance ?? Float.infinity
                    let minimumDistance = min(leftHandNearestDistance, rightHandNearestDistance)
                    
                    guard minimumDistance != Float.infinity else { continue }
                    
                    switch visualization.type {
                    case .box:
                        if leftHandNearestDistance < Constants.minimumFingerDistance
                            || rightHandNearestDistance < Constants.minimumFingerDistance
                        {
                            modelEntity.isEnabled = false
                            
                            if recipeStep == .step2 {
                                recipeStep = .step3
                            }
                        } else {
                            modelEntity.isEnabled = true
                        }
                        
                        if leftHandNearestDistance < Constants.maximumInteractionDistance {
                            let amplitude: Float = calculateAmplitude(for: leftHandNearestDistance)
                            boxHandProximity = .proximity(.left, modelEntity, amplitude)
                        } else {
                            boxHandProximity = .proximity(.left, modelEntity, Constants.swellDefaultAmplitude)
                        }
                        
                        if rightHandNearestDistance < Constants.maximumInteractionDistance {
                            let window: Float = calculateWindow(for: rightHandNearestDistance)
                            boxHandProximity = .proximity(.right, modelEntity, window)
                        } else {
                            boxHandProximity = .proximity(.right, modelEntity, Constants.swellDefaultWindow)
                        }
                    case .dutchOven:
                        if leftHandNearestDistance < Constants.minimumFingerDistance,
                           rightHandNearestDistance < Constants.minimumFingerDistance
                        {
                            dutchOvenGrip = .both(modelEntity)
                            
                            if recipeStep == .step1 {
                                recipeStep = .step2
                            }
                        } else if rightHandNearestDistance < Constants.minimumFingerDistance {
                            dutchOvenGrip = .right(modelEntity)
                        } else if leftHandNearestDistance < Constants.minimumFingerDistance {
                            dutchOvenGrip = .left(modelEntity)
                        } else {
                            dutchOvenGrip = .none(modelEntity)
                        }
                    case .milk:
                        if leftHandNearestDistance < Constants.minimumFingerDistance
                            || rightHandNearestDistance < Constants.minimumFingerDistance
                        {
                            visualization.entity.findEntity(named: "MilkMagic")?.isEnabled = false
                            visualization.entity.findEntity(named: "MilkBubbles")?.isEnabled = true
                            
                            if recipeStep == .step3 {
                                recipeStep = .complete
                            }
                        } else {
                            visualization.entity.findEntity(named: "MilkMagic")?.isEnabled = true
                            visualization.entity.findEntity(named: "MilkBubbles")?.isEnabled = false
                        }
                    case .none:
                        fatalError("Unknown ObjectAnchorVisualization.type in processHandUpdates")
                    }
                }
            }
        }
    }
    
    private func processObjectUpdates(with rootEntity: Entity) async {
        guard let objectTrackingProvider else {
            print("Error obtaining objectTrackingProvider upon processObjectUpdates")
            
            return
        }
        
        for await anchorUpdate in objectTrackingProvider.anchorUpdates {
            let anchor = anchorUpdate.anchor
            let id = anchor.id
            
            switch anchorUpdate.event {
            case .added:
                // Create a new visualization for the reference object that ARKit just detected.
                // The app displays the USDZ file that the reference object was trained on as
                // a wireframe on top of the real-world object.
                let model: Entity? = referenceObjectLoader.usdzsPerReferenceObjectID[anchor.referenceObject.id]
                let visualization = await ObjectAnchorVisualization(for: anchor,
                                                                    withModel: model)
                objectVisualizations[id] = visualization
                rootEntity.addChild(visualization.entity)
            case .updated:
                objectVisualizations[id]?.update(with: anchor)
            case .removed:
                objectVisualizations[id]?.entity.removeFromParent()
                objectVisualizations.removeValue(forKey: id)
            }
        }
    }
}
