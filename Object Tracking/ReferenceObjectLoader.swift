//
//  ReferenceObjectLoader.swift
//  Object Tracking
//
//  Created by Tony Morales on 6/25/24.
//

import ARKit
import RealityKit

@MainActor
@Observable
class ReferenceObjectLoader {
    private(set) var referenceObjects = [ReferenceObject]()
    private(set) var usdzsPerReferenceObjectID = [UUID: Entity]()
    
    func loadReferenceObjects() async {
        var referenceObjectFiles: [String] = []
        
        if let resourcesPath: String = Bundle.main.resourcePath {
            do {
                try referenceObjectFiles = FileManager.default.contentsOfDirectory(atPath: resourcesPath).filter { $0.hasSuffix(".referenceobject") }
            } catch {
                fatalError("Failed to load reference object files with error: \(error)")
            }
        }
        
        await withTaskGroup(of: Void.self) { [weak self] group in
            guard let self else { return }
            
            for file in referenceObjectFiles {
                let objectURL: URL = Bundle.main.bundleURL.appending(path: file)
                
                group.addTask {
                    await self.loadReferenceObject(objectURL)
                }
            }
        }
    }
    
    private func loadReferenceObject(_ url: URL) async {
        var referenceObject: ReferenceObject
        
        do {
            try await referenceObject = ReferenceObject(from: url)
        } catch {
            fatalError("Failed to load reference object at \(url) with error: \(error)")
        }
        
        referenceObjects.append(referenceObject)
        
        guard let usdzPath: URL = referenceObject.usdzFile else {
            print("Unable to find referenceObject.usdzFileURL")
            return
        }
            
        var entity: Entity?
        
        do {
            try await entity = Entity(contentsOf: usdzPath)
        } catch {
            print("Failed to load referenceObject.usdzFile")
        }
        
        entity?.name = url.deletingPathExtension().lastPathComponent
        usdzsPerReferenceObjectID[referenceObject.id] = entity
    }
}
