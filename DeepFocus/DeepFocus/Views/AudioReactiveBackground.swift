import SwiftUI

struct BlobSeed {
    let x0: Double
    let y0: Double
    let baseRadius: Double
    let phase0: Double
    let speed: Double
    let driftX: Double
    let driftY: Double
}

struct AudioReactiveBackground: View {
    let audioLevel: Float
    let active: Bool

    @State private var seeds: [BlobSeed] = []

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 1/60)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let energy = Double(audioLevel) * 1.2
                let op = active ? 1.0 : 0.0

                Canvas { context, canvasSize in
                    guard op > 0.001 else { return }

                    let blobSeeds = seeds
                    guard !blobSeeds.isEmpty else { return }

                    for seed in blobSeeds {
                        let phase = seed.phase0 + seed.speed * time * 1000
                        var x = seed.x0 + seed.driftX * time * 60
                        var y = seed.y0 + seed.driftY * time * 60
                        let w = canvasSize.width
                        let h = canvasSize.height

                        if x < -200 { x = w + 200 }
                        if x > w + 200 { x = -200 }
                        if y < -200 { y = h + 200 }
                        if y > h + 200 { y = -200 }

                        let breathe = sin(phase) * 0.15
                        let pulse = energy * 1.2
                        let radius = seed.baseRadius * (1 + breathe + pulse)
                        let baseAlpha = 0.012 + energy * 0.025
                        let alpha = baseAlpha * op

                        let center = CGPoint(x: x, y: y)
                        let gradient = Gradient(colors: [
                            Color.white.opacity(alpha),
                            Color.white.opacity(alpha * 0.4),
                            Color.white.opacity(0)
                        ])
                        context.fill(
                            Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                            with: .radialGradient(
                                gradient,
                                center: center,
                                startRadius: 0,
                                endRadius: radius
                            )
                        )
                    }
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                if seeds.isEmpty {
                    seeds = (0..<5).map { _ in
                        BlobSeed(
                            x0: geo.size.width * (0.2 + Double.random(in: 0...0.6)),
                            y0: geo.size.height * (0.2 + Double.random(in: 0...0.6)),
                            baseRadius: 80 + Double.random(in: 0...160),
                            phase0: Double.random(in: 0...(2 * .pi)),
                            speed: 0.0003 + Double.random(in: 0...0.0006),
                            driftX: (Double.random(in: 0...1) - 0.5) * 0.15,
                            driftY: (Double.random(in: 0...1) - 0.5) * 0.15
                        )
                    }
                }
            }
        }
    }
}
