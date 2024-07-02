//
//  ObjectAnchorVisualization.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/26/24.
//

import ARKit
import RealityKit
import RealityKitContent

@MainActor
class ObjectAnchorVisualization {
    enum ObjectType: String {
        case box
        case dutchOven
        case milk
    }
    
    var entity: Entity
    var type: ObjectType?
    
    private let textBaseHeight: Float = 0.08
    private let alpha: CGFloat = 0.7
    private let axisScale: Float = 0.05
    
    init(for anchor: ObjectAnchor,
         withModel model: Entity? = nil) async
    {
        guard let model else {
            print("Unable to find Reference Object model")
            entity = Entity()
            
            return
        }
        
        switch model.name.firstLowercased {
        case ObjectType.box.rawValue:
            self.type = .box
        case ObjectType.dutchOven.rawValue:
            self.type = .dutchOven
        case ObjectType.milk.rawValue:
            self.type = .milk
        default:
            fatalError("Attempted to create ObjectAnchorVisualization for unknown ObjectType")
        }
        
        let entity = Entity()
        
        guard let type else {
            self.entity = entity
            
            return
        }
        
        switch type {
        case .box:
            guard var modelComponent: ModelComponent = model.findEntity(named: Constants.objectCaptureMeshName)?.components[ModelComponent.self] else {
                print("Unable to access modelComponent in ObjectAnchorVisualization")
                self.entity = entity
                
                return
            }
            
            if let originalMaterial = modelComponent.materials.first as? PhysicallyBasedMaterial,
               let originalTexture: PhysicallyBasedMaterial.Texture = originalMaterial.baseColor.texture,
               var material = try? await ShaderGraphMaterial(named: "/Root/SwellMaterial",
                                                             from: "Immersive.usda",
                                                             in: realityKitContentBundle)
            {
                try? material.setParameter(name: "ShaderInputImage",
                                           value: .textureResource(originalTexture.resource))
                modelComponent.materials = [material]
                model.findEntity(named: Constants.objectCaptureMeshName)?.components[ModelComponent.self] = modelComponent
            }
            
            entity.addChild(model)
        case .dutchOven:
            let originVisualization = Entity.createAxes(axisScale: axisScale,
                                                        alpha: alpha)
            
            var wireframeMaterial = PhysicallyBasedMaterial()
            wireframeMaterial.triangleFillMode = .lines
            wireframeMaterial.faceCulling = .back
            wireframeMaterial.baseColor = .init(tint: .yellow)
            wireframeMaterial.blending = .transparent(opacity: 0.5)
            model.applyMaterialRecursively(wireframeMaterial)
            
            let descriptionEntity = Entity.createText(model.name,
                                                      height: textBaseHeight * axisScale)
            descriptionEntity.transform.translation.x = textBaseHeight * axisScale
            descriptionEntity.transform.translation.y = anchor.boundingBox.extent.y * 0.5
            
            entity.addChild(originVisualization)
            entity.addChild(model)
            entity.addChild(descriptionEntity)
        case .milk:
            guard let magicParticles = try? await Entity(named: "MilkMagic",
                                                         in: realityKitContentBundle),
                  let bubblesParticles = try? await Entity(named: "MilkBubbles",
                                                           in: realityKitContentBundle)
            else {
                print("Unable to access MilkMagic, MilkBubbles scenes")
                self.entity = entity
                
                return
            }
            
            bubblesParticles.isEnabled = false
            entity.addChild(magicParticles)
            entity.addChild(bubblesParticles)
        }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
        entity.isEnabled = anchor.isTracked
        
        self.entity = entity
    }
    
    func update(with anchor: ObjectAnchor) {
        entity.isEnabled = anchor.isTracked
        
        guard anchor.isTracked else { return }
        
        entity.transform = Transform(matrix: anchor.originFromAnchorTransform)
    }
}
