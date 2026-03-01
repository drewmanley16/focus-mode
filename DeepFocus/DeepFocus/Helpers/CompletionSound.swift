import AVFoundation
import AppKit

/// Plays a gentle 3-note chord on session complete (C5, E5, G5).
enum CompletionSound {
    private static var engineHolder: AVAudioEngine?

    static func play() {
        let frequencies: [Float] = [523.25, 659.25, 783.99] // C5, E5, G5

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) else { return }

        let engine = AVAudioEngine()
        engineHolder = engine

        let mixer = AVAudioMixerNode()
        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        let sampleRate = Float(format.sampleRate)
        let duration: Float = 0.3
        let frameCount = AVAudioFrameCount(duration * sampleRate)

        do {
            try engine.start()
        } catch {
            NSSound.beep()
            engineHolder = nil
            return
        }

        for (i, freq) in frequencies.enumerated() {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: format)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { continue }
            buffer.frameLength = frameCount

            let angularFreq = 2 * Float.pi * freq / sampleRate
            guard let data = buffer.floatChannelData?[0] else { continue }
            for j in 0..<Int(frameCount) {
                data[j] = sin(angularFreq * Float(j)) * 0.08
            }

            let delaySamples = Int(sampleRate * 0.12) * i
            let startTime = AVAudioTime(sampleTime: AVAudioFramePosition(delaySamples), atRate: Double(sampleRate))
            node.scheduleBuffer(buffer, at: startTime, options: [])
            node.play()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            engine.stop()
            engineHolder = nil
        }
    }
}
