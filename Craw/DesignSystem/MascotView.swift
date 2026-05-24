import DotLottie
import SwiftUI

enum Mascot: String {
    case birdFlying = "bird_flying"
    case owl
    case penguin
    case pigeon
}

struct MascotView: View {
    let mascot: Mascot
    var loops: Bool = true
    var autoplay: Bool = true

    var body: some View {
        DotLottieAnimation(
            fileName: mascot.rawValue,
            config: AnimationConfig(autoplay: autoplay, loop: loops)
        )
        .view()
    }
}

#Preview {
    VStack(spacing: 24) {
        MascotView(mascot: .birdFlying).frame(height: 160)
        MascotView(mascot: .owl).frame(height: 160)
        MascotView(mascot: .pigeon).frame(height: 64)
        MascotView(mascot: .penguin).frame(height: 64)
    }
    .padding()
}
