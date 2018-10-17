import ARKit

@objc public protocol EyeTrackerObjCDelegate: class {
    @objc func eyeTrackerDidUpdateTrackingState(_ eyeTracker: EyeTrackerObjC)
}

@objc public class EyeTrackerObjC: NSObject, EyeTrackerDelegate {
    @objc public static let invalidPosition = CGPoint(x: CGFloat.nan, y: .nan)

    @objc public enum ScreenEdge: Int {
        case top, left, right, bottom, invalid

        init(edge: EyeTracker.ScreenEdge) {
            switch edge {
            case .top: self = .top
            case .bottom: self = .bottom
            case .left: self = .left
            case .right: self = .right
            }
        }
    }

    @objc public class var isSupported: Bool {
        guard #available(iOS 12.0, *) else { return false }
        return ARFaceTrackingConfiguration.isSupported
    }

    @objc public var currentFrame: ARFrame? {
        return tracker.currentFrame
    }
    @objc public var screenDisplacement: Float {
        get { return tracker.screenDisplacement }
        set { tracker.screenDisplacement = screenDisplacement }
    }
    @objc public var screenPosition: CGPoint {
        switch tracker.state {
        case let .screenIn(position),
             let .screenOut(_, position):
            return position
        default:
            return EyeTrackerObjC.invalidPosition
        }
    }
    @objc public var edge: ScreenEdge {
        switch tracker.state {
        case let .screenOut(edge, _):
            return ScreenEdge(edge: edge)
        default:
            return .invalid
        }
    }
    @objc public weak var delegate: EyeTrackerObjCDelegate?

    private let tracker = EyeTracker()

    @objc public override init() {
        super.init()

        tracker.delegate = self
    }

    @objc public func start() {
        tracker.start()
    }

    @objc public func pause() {
        tracker.pause()
    }

    // MARK: - EyeTrackerDelegate

    public func eyeTracker(_ eyeTracker: EyeTracker, didUpdateTrackingState state: EyeTracker.TrackingState) {
        delegate?.eyeTrackerDidUpdateTrackingState(self)
    }
}
