import AVFoundation
import Combine

final class AmbientAudioEngine: ObservableObject {
    private var engine: AVAudioEngine?
    private var mixer: AVAudioMixerNode?
    private var players: [AVAudioPlayerNode] = []
    private var isRunning = false

    @Published var audioLevel: Float = 0

    func start() {
        guard !isRunning else { return }

        let eng = AVAudioEngine()
        let mixerNode = AVAudioMixerNode()
        // Use fixed 44.1kHz stereo — mainMixerNode.outputFormat can be invalid (0 channels) at startup
        guard let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2) else { return }

        eng.attach(mixerNode)

        // Use stereo throughout to avoid channel count mismatches
        // Layer 1: Soft filtered noise
        let noiseNode = createNoiseSource(format: stereoFormat)
        eng.attach(noiseNode)
        eng.connect(noiseNode, to: mixerNode, format: stereoFormat)

        // Layer 2: Drones (C2, G2, C3)
        let droneFreqs: [Float] = [65.41, 98.0, 130.81]
        for freq in droneFreqs {
            let drone = createDrone(frequency: freq, format: stereoFormat)
            eng.attach(drone)
            eng.connect(drone, to: mixerNode, format: stereoFormat)
            players.append(drone)
        }

        // Layer 3: Shimmer (C5)
        let shimmer = createShimmer(format: stereoFormat)
        eng.attach(shimmer)
        eng.connect(shimmer, to: mixerNode, format: stereoFormat)
        players.append(shimmer)

        eng.connect(mixerNode, to: eng.mainMixerNode, format: stereoFormat)

        // Install tap for level metering (must match mixer output format)
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: stereoFormat) { [weak self] buffer, _ in
            var sum: Float = 0
            let channelData = buffer.floatChannelData?[0]
            guard let data = channelData else { return }
            for i in 0..<Int(buffer.frameLength) {
                sum += abs(data[i])
            }
            let avg = sum / Float(buffer.frameLength)
            DispatchQueue.main.async {
                self?.audioLevel = min(1, avg * 10)
            }
        }

        mixerNode.outputVolume = 0.15

        do {
            try eng.start()
            for p in players { p.play() }
            engine = eng
            mixer = mixerNode
            isRunning = true
        } catch {
            print("AmbientAudioEngine failed to start: \(error)")
        }
    }

    func stop() {
        mixer?.removeTap(onBus: 0)
        players.forEach { $0.stop() }
        players = []
        engine?.stop()
        engine = nil
        mixer = nil
        isRunning = false
        audioLevel = 0
    }

    private func createNoiseSource(format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            var last: [Float] = [0, 0]

            for frame in 0..<Int(frameCount) {
                for ch in 0..<ablPointer.count {
                    let data = ablPointer[ch].mData?.assumingMemoryBound(to: Float.self)
                    guard let d = data else { continue }
                    let white = Float.random(in: -1...1)
                    last[ch] = last[ch] * 0.986 + white * 0.014
                    d[frame] = last[ch] * 0.3 * 4
                }
            }
            return noErr
        }
    }

    private func createDrone(frequency: Float, format: AVAudioFormat) -> AVAudioPlayerNode {
        let player = AVAudioPlayerNode()
        let buffer = createToneBuffer(frequency: frequency, duration: 10, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = 0.35
        return player
    }

    private func createToneBuffer(frequency: Float, duration: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            fatalError("Cannot create buffer")
        }
        buffer.frameLength = frameCount

        let angularFreq = 2 * Float.pi * frequency / Float(format.sampleRate)
        for ch in 0..<Int(format.channelCount) {
            guard let data = buffer.floatChannelData?[ch] else { continue }
            for i in 0..<Int(frameCount) {
                data[i] = sin(angularFreq * Float(i))
            }
        }
        return buffer
    }

    private func createShimmer(format: AVAudioFormat) -> AVAudioPlayerNode {
        let player = AVAudioPlayerNode()
        let buffer = createToneBuffer(frequency: 523.25, duration: 10, format: format)
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.volume = 0.08
        return player
    }
}
