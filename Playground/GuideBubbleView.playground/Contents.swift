import UIKit
import PlaygroundSupport

class MyViewController : UIViewController {

    var label: UILabel = {
        let label = UILabel()
        label.text = "Hello World!"
        label.textColor = .black
        return label
    }()

    var bubbleView = LHGuideBubbleView(arrowDirection: .up)

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        view.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 0).isActive = true

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bubbleView.tapBlankAreaDismiss = false
        bubbleView.bubbleText = "Tap Me"
        bubbleView.isHidden = false
        bubbleView.willDismissClosure = {
            print("bubbleView tapped")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        bubbleView.bubblePosition = CGPoint(x: label.frame.midX, y: label.frame.maxY + 10)
    }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
