import SwiftUI
import RealityKit
import ARKit

struct VoiceBoxARView: UIViewRepresentable {
    
    var text: String
    
    class Coordinator {
        var anchorEntity: AnchorEntity?
        var voiceBoxEntity: ModelEntity?
        var textEntity: ModelEntity?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)

        let anchorEntity = AnchorEntity(world: [0.25, -0.25, -0.5])
        context.coordinator.anchorEntity = anchorEntity

        do {
            let voiceBoxEntity = try ModelEntity.loadModel(named: "Larynx Muscles Ligaments 3D Model")
            voiceBoxEntity.generateCollisionShapes(recursive: true)
            voiceBoxEntity.transform.scale = SIMD3<Float>(0.003, 0.003, 0.003)
            voiceBoxEntity.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            voiceBoxEntity.position = [0, 0, 0]
            context.coordinator.voiceBoxEntity = voiceBoxEntity

            let textEntity = createTextEntity(text)
            textEntity.position = [225, 250, 0]
            textEntity.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            context.coordinator.textEntity = textEntity

            anchorEntity.addChild(voiceBoxEntity)
            voiceBoxEntity.addChild(textEntity)
            
        } catch {
            print("Error loading 3D Voice Box model: \(error)")
        }

        arView.scene.addAnchor(anchorEntity)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
    }

    func createTextEntity(_ text: String) -> ModelEntity {
        let mesh = MeshResource.generateText(
            text,
            font: .systemFont(ofSize: 5),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let material = SimpleMaterial(color: .white, roughness: 0, isMetallic: false)
        let textEntity = ModelEntity(mesh: mesh, materials: [material])
        
        textEntity.transform.scale = SIMD3<Float>(repeating: 3.0)
        
        return textEntity
    }
}
