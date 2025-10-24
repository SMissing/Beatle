import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

public struct NoiseOverlay: View {
    private let context = CIContext()
    private let filter = CIFilter.randomGenerator()
    var opacity: CGFloat = 0.05
    var scale: CGFloat = 1.0

    public init(opacity: CGFloat = 0.05, scale: CGFloat = 1.0) {
        self.opacity = opacity
        self.scale = scale
    }

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Canvas { ctx, _ in
                guard let img = filter.outputImage?
                    .transformed(by: CGAffineTransform(scaleX: scale, y: scale)) else { return }
                if let cg = context.createCGImage(img, from: CGRect(origin: .zero, size: size)) {
                    ctx.opacity = Double(opacity)
                    ctx.draw(Image(decorative: cg, scale: 1.0), in: CGRect(origin: .zero, size: size))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
