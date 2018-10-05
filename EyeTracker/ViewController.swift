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

        UIApplication.shared.keyWindow?.addSubview(pointView)
        pointView.backgroundColor = .red
        pointView.layer.cornerRadius = 5.0
        pointView.center = view.center
        pointView.layer.zPosition = 333

        eyeTracker.start()
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

    // MARK: - EyeTrackerDelegate

    func eyeTracker(_ eyeTracker: EyeTracker, didUpdateTrackingState state: EyeTracker.TrackingState) {
        switch state {
        case .screenIn(let screenPos):
            pointView.center = screenPos
        case .screenOut:
            break
        case .notTracked:
            break
        case .pausing:
            break
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
