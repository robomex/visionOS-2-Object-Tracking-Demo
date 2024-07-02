//
//  Extensions.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/26/24.
//

import ARKit
import RealityKit
import SwiftUI

extension Entity {
    static func createAxes(axisScale: Float, 
                           alpha: CGFloat = 1.0) -> Entity
    {
        let axisEntity = Entity()
        let mesh = MeshResource.generateBox(size: [1.0, 1.0, 1.0])

        let xAxis = ModelEntity(mesh: mesh, 
                                materials: [UnlitMaterial(color: .red.withAlphaComponent(alpha))])
        let yAxis = ModelEntity(mesh: mesh, 
                                materials: [UnlitMaterial(color: .green.withAlphaComponent(alpha))])
        let zAxis = ModelEntity(mesh: mesh, 
                                materials: [UnlitMaterial(color: .blue.withAlphaComponent(alpha))])
        axisEntity.children.append(contentsOf: [xAxis, yAxis, zAxis])

        let axisMinorScale: Float = axisScale / 20
        let axisAxisOffset: Float = axisScale / 2.0 + axisMinorScale / 2.0
        
        xAxis.position = [axisAxisOffset, 0, 0]
        xAxis.scale = [axisScale, axisMinorScale, axisMinorScale]
        yAxis.position = [0, axisAxisOffset, 0]
        yAxis.scale = [axisMinorScale, axisScale, axisMinorScale]
        zAxis.position = [0, 0, axisAxisOffset]
        zAxis.scale = [axisMinorScale, axisMinorScale, axisScale]
        
        return axisEntity
    }
    
    static func createText(_ string: String,
                           height: Float,
                           color: Color = .white) -> ModelEntity
    {
        guard let font = MeshResource.Font(name: "Helvetica",
                                           size: CGFloat(height))
        else {
            print("Error creating MeshResource from font")
            
            return ModelEntity()
        }
        
        let mesh = MeshResource.generateText(string,
                                             extrusionDepth: height * 0.05,
                                             font: font)
        let material = UnlitMaterial(color: UIColor(color))
        let text = ModelEntity(mesh: mesh, 
                               materials: [material])
    
        return text
    }
    
    func applyMaterialRecursively(_ material: RealityKit.Material) {
        if let modelEntity = self as? ModelEntity {
            modelEntity.model?.materials = [material]
        }
        
        for child in children {
            child.applyMaterialRecursively(material)
        }
    }
}

extension HandAnchor {
    enum Finger: CaseIterable {
        case thumb, index, middle, ring, little

        var jointName: HandSkeleton.JointName {
            switch self {
            case .thumb: return .thumbTip
            case .index: return .indexFingerTip
            case .middle: return .middleFingerTip
            case .ring: return .ringFingerTip
            case .little: return .littleFingerTip
            }
        }
    }

    func fingerPosition(_ finger: Finger) -> SIMD3<Float>? {
        guard isTracked,
              let fingerJoint = handSkeleton?.joint(finger.jointName) 
        else {
            return nil
        }
        
        let fingerTipFromOrigin: simd_float4x4 = originFromAnchorTransform * fingerJoint.anchorFromJointTransform
        
        return simd_make_float3(fingerTipFromOrigin.columns.3)
    }

    func allFingerPositions() -> [Finger: SIMD3<Float>] {
        var positions: [Finger: SIMD3<Float>] = [:]
        
        for finger in Finger.allCases {
            if let position: SIMD3<Float> = fingerPosition(finger) {
                positions[finger] = position
            }
        }
        
        return positions
    }
    
    func nearestFingerDistance(to modelEntity: ModelEntity) -> (finger: Finger,
                                                                distance: Float)?
    {
        guard isTracked,
              let bounds: BoundingBox = modelEntity.model?.mesh.bounds
        else {
            print("Failed to either findEntity(named: \(Constants.objectCaptureMeshName)) or its bounds")
            return nil
        }
        
        return Finger.allCases.compactMap { finger in
            guard let worldFingerPosition: SIMD3<Float> = fingerPosition(finger) else { return nil }
            
            let localFingerPosition: SIMD3<Float> = modelEntity.convert(position: worldFingerPosition,
                                                                       from: nil)
            let distanceSquared: Float = bounds.distanceSquared(toPoint: localFingerPosition)
            
            return (finger, distanceSquared.squareRoot())
        }.min(by: { $0.distance < $1.distance })
    }
}

extension ModelEntity {
    func replaceBaseColor(with color: UIColor) {
        guard var material = model?.materials.first as? PhysicallyBasedMaterial else {
            print("Unable to access ModelEntity's first material to replaceBaseColor")
            
            return
        }
        
        material.baseColor = .init(tint: color)
        model?.materials = [material]
    }
    
    func setShaderGraphParameter(for chirality: HandAnchor.Chirality,
                                 to value: Float)
    {
        guard var material = model?.materials.first as? ShaderGraphMaterial else {
            print("Unable to access ModelEntity's first material to setShaderGraphParameter")
            
            return
        }
        
        do {
            switch chirality {
            case .right:
                try material.setParameter(name: "Window",
                                          value: MaterialParameters.Value.float(value))
            case .left:
                try material.setParameter(name: "Amplitude",
                                          value: MaterialParameters.Value.float(value))
            }
        } catch {
            print("Failed to setParameter in setShaderGraphParameter: \(error)")
        }
        
        model?.materials = [material]
    }
}

extension String {
    var firstLowercased: String {
        guard let firstChar = first else { return self }
        return firstChar.lowercased() + dropFirst()
    }
}
