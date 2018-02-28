//http://www.hangge.com/blog/cache/detail_1660.html

import UIKit

@objc public protocol ScratchCardDelegate {
    @objc optional func scratchBegin(point: CGPoint)
    @objc optional func scratchMoved(progress: Float)
    @objc optional func scratchEnded(point: CGPoint)
    @objc optional func scratchCancled(point: CGPoint)
}

public class ScratchMask: UIImageView {

    public weak var delegate: ScratchCardDelegate?
    public var lineType: CGLineCap = .round
    public var lineWidth: CGFloat = 15
    private var lastPoint: CGPoint?

    public override required init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = true
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func eraseMask(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        defer {
            UIGraphicsEndImageContext()
        }

        image?.draw(in: bounds)

        let path = CGMutablePath()
        path.move(to: fromPoint)
        path.addLine(to: toPoint)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setShouldAntialias(true)
        context.setLineCap(lineType)
        context.setLineWidth(lineWidth)
        context.setBlendMode(.clear)
        context.addPath(path)
        context.strokePath()

        image = UIGraphicsGetImageFromCurrentImageContext()
    }

    private func getAlphaPixelPercent(image: UIImage) -> Float {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        let bitmapByteCount = width * height

        let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
        let colorSpace = CGColorSpaceCreateDeviceGray()

        defer {
            pixelData.deinitialize(count: bitmapByteCount)
            pixelData.deallocate(capacity: bitmapByteCount)
        }

        guard let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: colorSpace, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.alphaOnly.rawValue).rawValue) else { return 0 }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.clear(rect)
        context.draw(image.cgImage!, in: rect)

        //计算透明像素个数
        var alphaPixelCount = 0
        for x in 0...Int(width) {
            for y in 0...Int(height) {
                if pixelData[y * width + x] == 0 {
                    alphaPixelCount += 1
                }
            }
        }

        return Float(alphaPixelCount) / Float(bitmapByteCount)
    }
}

//MARK: - Touch
extension ScratchMask {
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        lastPoint = touch.location(in: self)

        delegate?.scratchBegin?(point: lastPoint!)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let point = lastPoint, let image = image else { return }

        let newPoint = touch.location(in: self)
        eraseMask(fromPoint: point, toPoint: newPoint)

        lastPoint = newPoint

        guard let scratchMoved = delegate?.scratchMoved else { return }
        let progress = getAlphaPixelPercent(image: image)

        scratchMoved(progress)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }

        delegate?.scratchEnded?(point: lastPoint!)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }

        delegate?.scratchCancled?(point: lastPoint!)
    }
}

