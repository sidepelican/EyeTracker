import ARKit

@available(iOS 11.0, *)
public protocol EyeTrackerDelegate: class {
    func eyeTracker(_ eyeTracker: EyeTracker, didUpdateTrackingState state: EyeTracker.TrackingState)
}

@available(iOS 11.0, *)
public class EyeTracker: NSObject, ARSessionDelegate {
    public enum TrackingState {
        case screenIn(CGPoint)
        case screenOut(ScreenEdge)
        case notTracked
        case pausing
    }

    public enum ScreenEdge: CaseIterable {
        case top, left, right, bottom
    }

    private var session: ARSession!
    private(set) var state: TrackingState = .pausing
    private var positionLogs: [CGPoint] = []
    private var lastUsedPositonLogIndex: Int = 0

    public var currentFrame: ARFrame? {
        return session.currentFrame
    }
    public weak var delegate: EyeTrackerDelegate?
    public var screenDisplacement: Float = 0.043

    public class var isSupported: Bool {
        guard #available(iOS 12.0, *) else { return false }
        return ARFaceTrackingConfiguration.isSupported
    }

    public func start() {
        session = ARSession()
        session.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        session.run(configuration)
    }

    public func pause() {
        session.pause()
        state = .pausing
    }

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        delegate?.eyeTracker(self, didUpdateTrackingState: state)
        state = .notTracked
    }

    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard #available(iOS 12.0, *) else { return }

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
        let smoothPos = smoothingPosition(with: screenPos)

        if UIScreen.main.bounds.contains(smoothPos) {
            state = .screenIn(smoothPos)
        } else {
            switch (smoothPos.x, smoothPos.y) {
            case (_, ...0):
                state = .screenOut(.top)
            case (_, viewport.height...):
                state = .screenOut(.bottom)
            case (...0, _):
                state = .screenOut(.left)
            case (viewport.width..., _):
                state = .screenOut(.right)
            default:
                fatalError("must not come here")
            }
        }
    }

    private func smoothingPosition(with newPosition: CGPoint) -> CGPoint {
        let logLimit = 10
        if positionLogs.count >= logLimit {
            if lastUsedPositonLogIndex > logLimit - 1 {
                lastUsedPositonLogIndex = 0
            }
            positionLogs[lastUsedPositonLogIndex] = newPosition
            lastUsedPositonLogIndex += 1
        } else {
            positionLogs.append(newPosition)
        }

        let sum = positionLogs.reduce(into: CGPoint.zero) { sum, point in
            sum.x += point.x
            sum.y += point.y
        }
        let count = CGFloat(positionLogs.count)

        return CGPoint(x: sum.x / count, y: sum.y / count)
    }
}
