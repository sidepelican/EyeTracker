import ARKit

protocol EyeTrackerDelegate: class {
    func eyeTracker(_ eyeTracker: EyeTracker, didUpdateTrackingState state: EyeTracker.TrackingState)
}

public class EyeTracker: NSObject, ARSessionDelegate {
    enum TrackingState {
        case `in`(CGPoint)
        case out
        case notTracked
        case pausing
    }

    private let session = ARSession()
    var currentFrame: ARFrame? {
        return session.currentFrame
    }

    private(set) var state: TrackingState = .pausing {
        didSet {
            delegate?.eyeTracker(self, didUpdateTrackingState: state)
        }
    }

    weak var delegate: EyeTrackerDelegate?

    func start() {
        let configuration = ARFaceTrackingConfiguration()
        session.run(configuration)
    }

    func pause() {
        session.pause()
        state = .pausing
    }

    private func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
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

        state = .in(screenPos)
    }
}
