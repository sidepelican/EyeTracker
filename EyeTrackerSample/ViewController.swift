import EyeTracker
import UIKit

class ViewController: UIViewController, EyeTrackerDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private let pointView = CursorView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
    private let imageView = UIImageView()
    private let eyeTracker = EyeTracker()
    private var edgeViews: [EyeTracker.ScreenEdge: CAGradientLayer] = [:]
    private var pauseEyeGestureHittest = false

    override func viewDidLoad() {
        super.viewDidLoad()

        eyeTracker.delegate = self

        tableView.rowHeight = 180

        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.alpha = 0.3
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true

        let baseRect = UIScreen.main.bounds
        let edgeLayerWidth: CGFloat = 32.0
        EyeTracker.ScreenEdge.allCases.forEach { edge in
            let layer = CAGradientLayer()
            layer.colors = [UIColor.green.withAlphaComponent(0.4).cgColor, UIColor(white: 1.0, alpha: 0.0).cgColor]
            (layer.frame, _) = baseRect.divided(atDistance: edgeLayerWidth, from: edge.rectEdge)
            (layer.startPoint, layer.endPoint) = edge.direction
            navigationController?.view.layer.addSublayer(layer)
            layer.isHidden = true
            edgeViews[edge] = layer
        }

        navigationController?.view.addSubview(pointView)
        pointView.center = view.center

        if EyeTracker.isSupported {
            eyeTracker.start()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        pauseEyeGestureHittest = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        pauseEyeGestureHittest = false
    }

    @IBAction func navigationBarItemSwitchValueChanged(_ sender: UISwitch) {
        imageView.isHidden = !sender.isOn
    }

    private var currentHighlightedCell: UITableViewCell? {
        didSet {
            oldValue?.isHighlighted = false
            currentHighlightedCell?.isHighlighted = true
        }
    }

    private func hitTestCells(screenPosition: CGPoint) {
        if pauseEyeGestureHittest { return }

        if navigationController?.visibleViewController != self {
            if CGRect(x: 0, y: 30, width: 100, height: 70).contains(screenPosition) {
                pointView.progress += 0.03
                if pointView.progress >= 1.0 {
                    navigationController?.popViewController(animated: true)
                    clearSelection()
                }
            } else {
                clearSelection()
            }
            return
        }

        for cell in tableView.visibleCells {
            if cell.hitTest(cell.convert(screenPosition, from: nil), with: nil) == nil { continue }

            currentHighlightedCell = cell
            pointView.progress += 0.015

            if pointView.progress >= 1.0 {
                performSegue(withIdentifier: "Segue", sender: currentHighlightedCell)
                clearSelection()
            }

            return
        }

        clearSelection()
    }

    private func clearSelection() {
        currentHighlightedCell = nil
        pointView.progress = 0.0
    }

    private func scrollTableView(_ y: CGFloat) {
        var nextContentOffset = CGPoint(x: tableView.contentOffset.x, y: tableView.contentOffset.y + y)
        nextContentOffset.y = min(max(nextContentOffset.y, 0), tableView.contentSize.height - tableView.bounds.height)
        tableView.setContentOffset(nextContentOffset, animated: false)
    }

    // MARK: - EyeTrackerDelegate

    func eyeTracker(_ eyeTracker: EyeTracker, didUpdateTrackingState state: EyeTracker.TrackingState) {
        edgeViews.forEach { $1.isHidden = true }
        switch state {
        case .screenIn(let screenPos):
            pointView.isHidden = false
            pointView.center = screenPos
            hitTestCells(screenPosition: screenPos)
        case .screenOut(let edge):
            edgeViews[edge]?.isHidden = false
            switch edge {
            case .top:
                scrollTableView(-6)
            case .bottom:
                scrollTableView(6)
            default:
                break
            }
            pointView.isHidden = true
            clearSelection()
        case .notTracked:
            pointView.isHidden = true
            clearSelection()
        case .pausing:
            pointView.isHidden = true
            clearSelection()
        }

        if !imageView.isHidden, let currentFrame = eyeTracker.currentFrame {
            imageView.image = UIImage(cvImageBuffer: currentFrame.capturedImage, orientation: .right)
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ContentCell
        cell.titleLabel.text = "Content \(indexPath.item + 1)"
        return cell
    }
}

private extension UIImage {
    convenience init?(cvImageBuffer: CVImageBuffer, orientation: CGImagePropertyOrientation) {
        let ciImage = CIImage(cvImageBuffer: cvImageBuffer).oriented(orientation)
        let context = CIContext()
        let rect = CGRect(x: 0,
                          y: 0,
                          width: CVPixelBufferGetHeight(cvImageBuffer),
                          height: CVPixelBufferGetWidth(cvImageBuffer))

        guard let cgImage = context.createCGImage(ciImage, from: rect) else { return nil }
        self.init(cgImage: cgImage)
    }
}

private extension EyeTracker.ScreenEdge {
    var rectEdge: CGRectEdge {
        switch self {
        case .top:
            return .minYEdge
        case .left:
            return .minXEdge
        case .right:
            return .maxXEdge
        case .bottom:
            return .maxYEdge
        }
    }

    var direction: (CGPoint, CGPoint) {
        switch self {
        case .top:
            return (CGPoint(x: 0.5, y: 0.0), CGPoint(x: 0.5, y: 1.0))
        case .left:
            return (CGPoint(x: 0.0, y: 0.5), CGPoint(x: 1.0, y: 0.5))
        case .right:
            return (CGPoint(x: 1.0, y: 0.5), CGPoint(x: 0.0, y: 0.5))
        case .bottom:
            return (CGPoint(x: 0.5, y: 1.0), CGPoint(x: 0.5, y: 0.0))
        }
    }
}
