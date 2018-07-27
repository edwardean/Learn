//
//  LHGuideBubbleView.swift

import UIKit

public enum LHGuideBubbleArrowDirection: Int {
    case up, down
}

public class LHGuideBubbleView: UIView {
    private lazy var contentWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.isHidden = true
        window.backgroundColor = .clear
        return window
    }()

    public lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var shapeLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.isOpaque = false
        layer.fillColor = bubbleBackgroundColor.cgColor
        layer.anchorPoint = CGPoint.zero

        layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 4
        layer.shadowOpacity = 1
        return layer
    }()

    private var arrowDirection: LHGuideBubbleArrowDirection

    private var bubbleLeadingLayout: NSLayoutConstraint?
    private var bubbleTopLayout: NSLayoutConstraint?

    public var bubblePosition: CGPoint = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY) {
        didSet {
            layoutIfNeeded()
            setNeedsLayout()
        }
    }

    public var bubbleText: String? {
        didSet {
            label.text = bubbleText

            layoutIfNeeded()
            setNeedsLayout()
        }
    }

    public var willDismissClosure: (() -> Void)?

    public var tapBlankAreaDismiss: Bool = false

    public var bubbleBackgroundColor: UIColor = UIColor.blue {
        didSet {
            shapeLayer.fillColor = bubbleBackgroundColor.cgColor
        }
    }

    public required init(arrowDirection: LHGuideBubbleArrowDirection) {
        self.arrowDirection = arrowDirection
        super.init(frame: .zero)

        contentWindow.addSubview(self)
        layer.addSublayer(shapeLayer)
        addSubview(label)

        translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        label.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 0).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        label.widthAnchor.constraint(equalTo: widthAnchor, constant: -12).isActive = true
        label.heightAnchor.constraint(equalTo: heightAnchor, constant: -16).isActive = true

        bubbleLeadingLayout = leadingAnchor.constraint(equalTo: contentWindow.leadingAnchor)
        bubbleTopLayout = topAnchor.constraint(equalTo: contentWindow.topAnchor)

        bubbleLeadingLayout?.isActive = true
        bubbleTopLayout?.isActive = true
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        let arrowWith: CGFloat = bounds.height * 0.5
        let arrowHeight: CGFloat = arrowWith * 0.65

        bubbleLeadingLayout?.constant = bubblePosition.x - bounds.width * 0.5
        if arrowDirection == .up {
            bubbleTopLayout?.constant = bubblePosition.y + arrowHeight
        } else {
            bubbleTopLayout?.constant = bubblePosition.y - arrowHeight - bounds.height
        }

        let rectanglePath = UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height * 0.25)
        let arrowPath = UIBezierPath()
        arrowPath.move(to: .zero)
        arrowPath.addLine(to: CGPoint(x: arrowWith * 0.5, y: arrowDirection == .up ? -arrowHeight : arrowHeight))
        arrowPath.addLine(to: CGPoint(x: arrowWith, y: 0))
        arrowPath.close()
        arrowPath.apply(CGAffineTransform(translationX: (bounds.width - arrowWith) * 0.5, y: arrowDirection == .up ? 0 : bounds.height))

        rectanglePath.append(arrowPath)
        shapeLayer.path = rectanglePath.cgPath
    }

    public override var isHidden: Bool {
        didSet {
            contentWindow.isHidden = isHidden

            layoutIfNeeded()
            setNeedsLayout()
        }
    }

    private func dismiss() {
        willDismissClosure?()
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
        }) { _ in
            self.contentWindow.isHidden = true
            self.removeFromSuperview()
        }
    }

    public override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        let convertPoint = contentWindow.convert(point, from: self)
        let touchInContent = contentWindow.frame.contains(convertPoint)
        return touchInContent
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else {
            return
        }

        let point = touch.location(in: contentWindow)

        if !frame.insetBy(dx: -10, dy: -10).contains(point) {
            guard tapBlankAreaDismiss else {
                return
            }
        }

        dismiss()
    }
}
