import UIKit

class CursorView: UIView {
    var progress: CGFloat = 0.0 {
        didSet {
            progress = min(max(progress, 0.0), 1.0)
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        isOpaque = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var color: CGColor = UIColor.red.cgColor

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setFillColor(UIColor.clear.cgColor)
        context.fill(rect)

        context.addArc(center: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
                       radius: bounds.width * 0.34,
                       startAngle: 0.0,
                       endAngle: CGFloat.pi * 2.0,
                       clockwise: false)
        context.setFillColor(color.copy(alpha: 0.7)!)
        context.fillPath()

        context.addArc(center: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
                       radius: bounds.width * 0.44,
                       startAngle: CGFloat.pi * -0.5,
                       endAngle: CGFloat.pi * 2.0 * progress + CGFloat.pi * -0.5,
                       clockwise: false)
        context.setLineWidth(bounds.width * 0.13)
        context.setStrokeColor(color)
        context.strokePath()
    }
}
