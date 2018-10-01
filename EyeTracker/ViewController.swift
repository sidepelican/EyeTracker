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

    private let leftEyeNode = SCNNode(geometry: SCNSphere(radius: 0.007))

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.scene.rootNode.addChildNode(leftEyeNode)
        leftEyeNode.opacity = 0.7
        leftEyeNode.renderingOrder = 100
        leftEyeNode.geometry?.firstMaterial?.readsFromDepthBuffer = false
        leftEyeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow

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
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//        sceneView.scene = scene
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
        print(#function)

        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            return
        }

        leftEyeNode.simdTransform = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform)

        guard let cameraTransform = sceneView.pointOfView?.transform else { return }
        let cameraNode = SCNNode()
        cameraNode.transform = cameraTransform
        let faceNode = SCNNode()
        faceNode.transform = SCNMatrix4(faceAnchor.transform)

        let latPoint = faceNode.convertPosition(SCNVector3(faceAnchor.lookAtPoint), to: cameraNode)
        print("latPoint", latPoint)

        label.text = """
        x: \(latPoint.x)
        y: \(latPoint.y)
        z: \(latPoint.z)
        """
    }
}
