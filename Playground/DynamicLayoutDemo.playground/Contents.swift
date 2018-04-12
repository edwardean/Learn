//: A UIKit based Playground for presenting user interface

import UIKit
import PlaygroundSupport

typealias LHPopMenuItemClosure = (_ item: LHPopMenuItem) -> Void

class LHPopMenuItem: UIButton {
    private(set) var closure: LHPopMenuItemClosure?

    static func PopMenuItem(custom closure: LHPopMenuItemClosure, action: @escaping LHPopMenuItemClosure) -> LHPopMenuItem {
        let item = LHPopMenuItem(type: .custom)
        item.closure = action
        item.isExclusiveTouch = true
        closure(item)

        return item
    }
}

class LHPopMenu: UIView {
    let arrowWidth: CGFloat = 10
    let arrowHeight: CGFloat = 7

    private(set) var items: [LHPopMenuItem] = []
    private lazy var contentView: UIView = {
        let view = UIView()
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor, constant: arrowHeight).isActive = true

        return view
    }()

    private lazy var arrowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.isOpaque = false
        layer.fillColor = UIColor.white.cgColor

        layer.anchorPoint = CGPoint.zero
        layer.frame = CGRect(x: 0, y: 0, width: arrowWidth, height: arrowHeight)

        let path = UIBezierPath()
        path.move(to: .zero)

        path.addLine(to: CGPoint(x: CGFloat(arrowWidth/2), y: -CGFloat(arrowHeight)))
        path.addLine(to: CGPoint(x: arrowWidth, y: 0))

        path.close()
        layer.path = path.cgPath
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor.white

        contentView.layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor
        contentView.layer.shadowOffset = CGSize(width: 1, height: 1)
        contentView.layer.shadowRadius = 4
        contentView.layer.shadowOpacity = 1

        layer.addSublayer(arrowLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        arrowLayer.position = CGPoint(x: bounds.width - arrowWidth - 10, y: arrowHeight)

        let path = UIBezierPath(rect: contentView.bounds)
        if let arrowPathRef = arrowLayer.path {
            let arrowPath = UIBezierPath(cgPath: arrowPathRef)
            arrowPath.apply(CGAffineTransform(translationX: arrowLayer.position.x, y: 0))
            path.append(arrowPath)
        }
        contentView.layer.shadowPath = path.cgPath
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 125, height: UIViewNoIntrinsicMetric)
    }

    public func removeItems() {
        for item in items {
            item.removeFromSuperview()
        }
        items.removeAll()

        setNeedsLayout()
    }

    public func addItem(_ item: LHPopMenuItem) {
        item.removeTarget(self, action: #selector(LHPopMenu.itemAction), for: .touchUpInside)
        item.addTarget(self, action: #selector(LHPopMenu.itemAction), for: .touchUpInside)

        let lastItem = items.last

        items.append(item)
        contentView.addSubview(item)

        item.translatesAutoresizingMaskIntoConstraints = false
        item.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        item.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        item.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        item.heightAnchor.constraint(equalToConstant: 45).isActive = true

        if let last = lastItem {
            item.topAnchor.constraint(equalTo: last.bottomAnchor).isActive = true
        } else {
            item.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        }

        let bottomConstraint = item.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        let index = items.index(of: item) ?? 0
        bottomConstraint.priority = UILayoutPriority(UILayoutPriority.defaultHigh.rawValue + Float(index))
        bottomConstraint.isActive = true

        if let last = lastItem {
            let separatorLine = UIView()
            separatorLine.backgroundColor = UIColor(white: 0, alpha: 0.3)

            last.addSubview(separatorLine)
            separatorLine.translatesAutoresizingMaskIntoConstraints = false
            separatorLine.leadingAnchor.constraint(equalTo: last.leadingAnchor).isActive = true
            separatorLine.trailingAnchor.constraint(equalTo: last.trailingAnchor).isActive = true
            separatorLine.bottomAnchor.constraint(equalTo: last.bottomAnchor).isActive = true
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        }

        setNeedsLayout()
    }
}

extension LHPopMenu {
    @objc func itemAction(_ sender: LHPopMenuItem) {
        sender.closure?(sender)
    }
}

class MyViewController : UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.blue

        let item1 = LHPopMenuItem.PopMenuItem(custom: { item in
            configure(item)
            item.setTitle("item1", for: .normal)
        }) { item in
            print("item1")
        }

        let item2 = LHPopMenuItem.PopMenuItem(custom: { item in
            configure(item)
            item.setTitle("item2", for: .normal)
        }) { item in
            print("item2")
        }

        let item3 = LHPopMenuItem.PopMenuItem(custom: { item in
            configure(item)
            item.setTitle("item3", for: .normal)
        }) { item in
            print("item3")
        }

        let item4 = LHPopMenuItem.PopMenuItem(custom: { item in
            configure(item)
            item.setTitle("item4", for: .normal)
        }) { item in
            print("item4")
        }

        let item5 = LHPopMenuItem.PopMenuItem(custom: { item in
            configure(item)
            item.setTitle("item5", for: .normal)
        }) { item in
            print("item5")
        }

        let popMenu = LHPopMenu()
        view.addSubview(popMenu)

        popMenu.translatesAutoresizingMaskIntoConstraints = false
        popMenu.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        popMenu.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        popMenu.addItem(item1)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
            popMenu.addItem(item2)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
                popMenu.addItem(item3)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
                    popMenu.addItem(item4)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
                        popMenu.addItem(item5)
                    }
                }
            }
        }
    }

    private func configure(_ item: LHPopMenuItem) {
        item.setTitleColor(UIColor.darkGray, for: .normal)
        item.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
