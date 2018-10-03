//
//  ViewController.swift
//  EyeTracker
//
//  Created by kenta-okamura on 2018/10/01.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!

    private let pointView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    private let label = UILabel()

    private let rightEyeNode =  SCNNode(geometry: SCNSphere(radius: 0.007))
    private let rightEyeEndNode = SCNNode(geometry: SCNSphere(radius: 0.007))
    private let leftEyeNode = SCNNode(geometry: SCNSphere(radius: 0.007))
    private let leftEyeEndNode = SCNNode(geometry: SCNSphere(radius: 0.007))

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.scene.rootNode.addChildNode(rightEyeNode)
        rightEyeNode.opacity = 0.7
        rightEyeNode.renderingOrder = 100
        rightEyeNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
        rightEyeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow

        sceneView.scene.rootNode.addChildNode(rightEyeEndNode)
        rightEyeEndNode.opacity = 0.7
        rightEyeEndNode.renderingOrder = 100
        rightEyeEndNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
        rightEyeEndNode.geometry?.firstMaterial?.diffuse.contents = UIColor.gray

        sceneView.scene.rootNode.addChildNode(leftEyeNode)
        leftEyeNode.opacity = 0.7
        leftEyeNode.renderingOrder = 100
        leftEyeNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
        leftEyeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow

        sceneView.scene.rootNode.addChildNode(leftEyeEndNode)
        leftEyeEndNode.opacity = 0.7
        leftEyeEndNode.renderingOrder = 100
        leftEyeEndNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
        leftEyeEndNode.geometry?.firstMaterial?.diffuse.contents = UIColor.gray

        pointView.backgroundColor = .red
        pointView.layer.cornerRadius = 5.0
        view.addSubview(pointView)
        pointView.center = view.center

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        label.textColor = .white
        label.numberOfLines = 0

        sceneView.session.delegate = self

        sceneView.delegate = self
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARFaceTrackingConfiguration()

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        let node = SCNNode()
//
//        return node
//    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            return
        }

        let rightEyeSimdTransform = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform)
        let leftEyeSimdTransform = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform)

        var cameraTransform = session.currentFrame!.camera.transform

        var translation = matrix_identity_float4x4
        let p1 = cameraTransform.position
        translation.columns.3.x = 1.0
        cameraTransform = simd_mul(cameraTransform, translation)
        let p2 = cameraTransform.position
        translation = matrix_identity_float4x4
        translation.columns.3.y = 1.0
        cameraTransform = simd_mul(cameraTransform, translation)
        let p3 = cameraTransform.position

        let plane = Plane(p1: p1, p2: p2, p3: p3)
        let rightRay = Ray(origin: rightEyeSimdTransform.position,
                           direction: -rightEyeSimdTransform.frontVector)
        let leftRay = Ray(origin: leftEyeSimdTransform.position,
                          direction: -leftEyeSimdTransform.frontVector)

        translation = matrix_identity_float4x4
        translation.columns.3.z = rightRay.dist(with: plane) - 0.05
        let rightEyeEndSimdTransform = simd_mul(rightEyeSimdTransform, translation)
        translation.columns.3.z = leftRay.dist(with: plane) - 0.05
        let leftEyeEndSimdTransform = simd_mul(leftEyeSimdTransform, translation)

        let eyesMidPoint = (rightEyeEndSimdTransform.position + leftEyeEndSimdTransform.position) / 2

        let viewport = UIScreen.main.bounds.size
        let screenPos = session.currentFrame!.camera.projectPoint(eyesMidPoint, orientation: .portrait, viewportSize: viewport)

        print(screenPos)
        pointView.center = screenPos

        label.text = """
        x: \(screenPos.x)
        y: \(screenPos.y)
        """

        rightEyeNode.simdTransform = rightEyeSimdTransform
        leftEyeNode.simdTransform = leftEyeSimdTransform
        rightEyeEndNode.simdTransform = rightEyeEndSimdTransform
        leftEyeEndNode.simdTransform = leftEyeEndSimdTransform
    }
}

extension simd_float4x4 {
    var position: simd_float3 {
        return simd_float3(columns.3.x, columns.3.y, columns.3.z)
    }

    var frontVector: simd_float3 {
        return simd_float3(-columns.2.x, -columns.2.y, -columns.2.z)
    }
}
