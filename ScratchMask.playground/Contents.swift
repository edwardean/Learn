//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

class MyViewController : UIViewController, ScratchCardDelegate {

    var scratchCard: ScratchMask?

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        let label = UILabel()
        label.frame = CGRect(x: 150, y: 200, width: 200, height: 20)
        label.text = "Hello World!"
        label.textColor = .black
        
        view.addSubview(label)
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let couponView = UIImageView(image: UIImage(named: "coupon"))

        scratchCard = ScratchMask(frame: CGRect(x: 0, y: 0, width: 300, height: 250))
        scratchCard!.image = UIImage(named: "mask")
        scratchCard!.delegate = self

        couponView.frame = scratchCard!.frame
        view.addSubview(couponView)
        view.addSubview(scratchCard!)
    }
}

//MARK: ScratchCardDelegate
extension MyViewController {
    func scratchMoved(progress: Float) {
        if progress > 0.75 {
            scratchCard?.isHidden = true
        }
    }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
