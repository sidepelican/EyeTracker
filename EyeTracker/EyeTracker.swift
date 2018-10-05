import ARKit

protocol EyeTrackerDelegate: class {
    func eyeTracker(_ eyeTracker: EyeTracker, didUpdateTrackingState state: EyeTracker.TrackingState)
}

class EyeTracker: NSObject, ARSessionDelegate {
    enum TrackingState {
        case screenIn(CGPoint)
        case screenOut
        case notTracked
        case pausing
    }

    private var session: ARSession!
    private var displayLink: CADisplayLink?
    private(set) var state: TrackingState = .pausing

    var currentFrame: ARFrame? {
        return session.currentFrame
    }
    weak var delegate: EyeTrackerDelegate?
    var screenDisplacement: Float = 0.05

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(sync(with:)))
        displayLink?.add(to: .main, forMode: .common)

        session = ARSession()
        session.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        session.run(configuration)
    }

    func pause() {
        session.pause()
        displayLink?.invalidate()
        state = .pausing
    }

    @objc func sync(with display: CADisplayLink) {
        delegate?.eyeTracker(self, didUpdateTrackingState: state)
        state = .notTracked
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first,
            let camera = session.currentFrame?.camera else {
                return
        }

        let rightEyeSimdTransform = simd_mul(faceAnchor.transform, faceAnchor.rightEyeTransform)
        let leftEyeSimdTransform = simd_mul(faceAnchor.transform, faceAnchor.leftEyeTransform)

        var cameraTransform = camera.transform

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
        translation.columns.3.z = rightRay.dist(with: plane) - screenDisplacement
        let rightEyeEndSimdTransform = simd_mul(rightEyeSimdTransform, translation)
        translation.columns.3.z = leftRay.dist(with: plane) - screenDisplacement
        let leftEyeEndSimdTransform = simd_mul(leftEyeSimdTransform, translation)

        let eyesMidPoint = (rightEyeEndSimdTransform.position + leftEyeEndSimdTransform.position) / 2

        let viewport = UIScreen.main.bounds.size
        let screenPos = camera.projectPoint(eyesMidPoint, orientation: .portrait, viewportSize: viewport)

        state = .screenIn(screenPos)
    }
}
