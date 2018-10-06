//
//  ViewController.swift
//  EyeTracker
//
//  Created by kenta-okamura on 2018/10/01.
//

import UIKit

class ViewController: UIViewController, EyeTrackerDelegate, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private let pointView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    private let imageView = UIImageView()
    private let eyeTracker = EyeTracker()
    private var edgeViews: [EyeTracker.ScreenEdge: CAGradientLayer] = [:]

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
        pointView.backgroundColor = .red
        pointView.layer.cornerRadius = 5.0
        pointView.center = view.center
        pointView.layer.zPosition = 333

        if EyeTracker.isSupported {
            eyeTracker.start()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    @IBAction func navigationBarItemSwitchValueChanged(_ sender: UISwitch) {
        imageView.isHidden = !sender.isOn
    }

    private func scrollTableView(_ y: CGFloat) {
        tableView.flashScrollIndicators()
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
        case .screenOut(let edge):
            pointView.isHidden = true
            edgeViews[edge]?.isHidden = false
            switch edge {
            case .top:
                scrollTableView(-6)
            case .bottom:
                scrollTableView(6)
            default:
                break
            }
        case .notTracked:
            pointView.isHidden = true
        case .pausing:
            pointView.isHidden = true
        }

        if !imageView.isHidden, let currentFrame = eyeTracker.currentFrame {
            let ciImage = CIImage(cvImageBuffer: currentFrame.capturedImage).oriented(.right)
            let context = CIContext()
            let rect = CGRect(x: 0,
                              y: 0,
                              width: CVPixelBufferGetHeight(currentFrame.capturedImage),
                              height: CVPixelBufferGetWidth(currentFrame.capturedImage))

            let cgImage = context.createCGImage(ciImage, from: rect)

            if let cgImage = cgImage {
                imageView.image = UIImage(cgImage: cgImage)
                imageView.contentMode = .scaleAspectFill
            }
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

extension EyeTracker.ScreenEdge {
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
