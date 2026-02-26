"use client";

import { useEffect, useRef, useCallback } from "react";

interface AmbientAudioControllerProps {
  isPlaying: boolean;
  volume?: number;
  onAnalyser?: (analyser: AnalyserNode | null) => void;
}

function createSoftNoise(ctx: AudioContext): AudioBufferSourceNode {
  const seconds = 4;
  const bufferSize = seconds * ctx.sampleRate;
  const buffer = ctx.createBuffer(2, bufferSize, ctx.sampleRate);

  for (let ch = 0; ch < 2; ch++) {
    const data = buffer.getChannelData(ch);
    let last = 0;
    for (let i = 0; i < bufferSize; i++) {
      const white = Math.random() * 2 - 1;
      // Pink-ish filtered noise — much softer than brown
      last = last * 0.986 + white * 0.014;
      data[i] = last * 4;
    }
  }

  const source = ctx.createBufferSource();
  source.buffer = buffer;
  source.loop = true;
  source.start(0);
  return source;
}

function createDrone(
  ctx: AudioContext,
  freq: number,
  lfoRate: number,
  lfoDepth: number,
): { source: OscillatorNode; gain: GainNode } {
  const osc = ctx.createOscillator();
  osc.type = "sine";
  osc.frequency.setValueAtTime(freq, ctx.currentTime);

  // Slow LFO to modulate amplitude for an evolving feel
  const lfo = ctx.createOscillator();
  lfo.type = "sine";
  lfo.frequency.setValueAtTime(lfoRate, ctx.currentTime);

  const lfoGain = ctx.createGain();
  lfoGain.gain.setValueAtTime(lfoDepth, ctx.currentTime);

  const droneGain = ctx.createGain();
  droneGain.gain.setValueAtTime(1, ctx.currentTime);

  lfo.connect(lfoGain);
  lfoGain.connect(droneGain.gain);
  osc.connect(droneGain);

  lfo.start(0);
  osc.start(0);

  return { source: osc, gain: droneGain };
}

export default function AmbientAudioController({
  isPlaying,
  volume = 0.15,
  onAnalyser,
}: AmbientAudioControllerProps) {
  const ctxRef = useRef<AudioContext | null>(null);
  const masterGainRef = useRef<GainNode | null>(null);
  const nodesRef = useRef<AudioNode[]>([]);

  const start = useCallback(() => {
    if (ctxRef.current) return;

    const ctx = new AudioContext();
    const nodes: AudioNode[] = [];

    const masterGain = ctx.createGain();
    masterGain.gain.setValueAtTime(0, ctx.currentTime);
    masterGain.gain.linearRampToValueAtTime(volume, ctx.currentTime + 3);

    const analyser = ctx.createAnalyser();
    analyser.fftSize = 256;
    analyser.smoothingTimeConstant = 0.85;

    masterGain.connect(analyser);
    analyser.connect(ctx.destination);

    // Layer 1: Soft filtered noise — very quiet bed
    const noise = createSoftNoise(ctx);
    const noiseFilter = ctx.createBiquadFilter();
    noiseFilter.type = "lowpass";
    noiseFilter.frequency.setValueAtTime(400, ctx.currentTime);
    noiseFilter.Q.setValueAtTime(0.5, ctx.currentTime);

    const noiseGain = ctx.createGain();
    noiseGain.gain.setValueAtTime(0.3, ctx.currentTime);

    noise.connect(noiseFilter);
    noiseFilter.connect(noiseGain);
    noiseGain.connect(masterGain);
    nodes.push(noise);

    // Layer 2: Warm drones — C2 + G2 + C3, slowly breathing
    const drones = [
      createDrone(ctx, 65.41, 0.06, 0.3),  // C2, very slow breathe
      createDrone(ctx, 98.0, 0.045, 0.25),  // G2
      createDrone(ctx, 130.81, 0.03, 0.2),  // C3
    ];

    const droneGain = ctx.createGain();
    droneGain.gain.setValueAtTime(0.35, ctx.currentTime);

    const droneLowpass = ctx.createBiquadFilter();
    droneLowpass.type = "lowpass";
    droneLowpass.frequency.setValueAtTime(600, ctx.currentTime);

    for (const drone of drones) {
      drone.gain.connect(droneLowpass);
      nodes.push(drone.source);
    }
    droneLowpass.connect(droneGain);
    droneGain.connect(masterGain);

    // Layer 3: High shimmer — very quiet, sparse harmonic sparkle
    const shimmer1 = ctx.createOscillator();
    shimmer1.type = "sine";
    shimmer1.frequency.setValueAtTime(523.25, ctx.currentTime); // C5

    const shimmerLfo = ctx.createOscillator();
    shimmerLfo.type = "sine";
    shimmerLfo.frequency.setValueAtTime(0.08, ctx.currentTime);

    const shimmerLfoGain = ctx.createGain();
    shimmerLfoGain.gain.setValueAtTime(0.08, ctx.currentTime);

    const shimmerGain = ctx.createGain();
    shimmerGain.gain.setValueAtTime(0, ctx.currentTime);

    shimmerLfo.connect(shimmerLfoGain);
    shimmerLfoGain.connect(shimmerGain.gain);
    shimmer1.connect(shimmerGain);
    shimmerGain.connect(masterGain);

    shimmerLfo.start(0);
    shimmer1.start(0);
    nodes.push(shimmer1, shimmerLfo);

    ctxRef.current = ctx;
    masterGainRef.current = masterGain;
    nodesRef.current = nodes;

    onAnalyser?.(analyser);
  }, [volume, onAnalyser]);

  const stop = useCallback(() => {
    const ctx = ctxRef.current;
    const masterGain = masterGainRef.current;

    if (!ctx || !masterGain) return;

    onAnalyser?.(null);

    masterGain.gain.linearRampToValueAtTime(0, ctx.currentTime + 2);

    setTimeout(() => {
      ctx.close();
      ctxRef.current = null;
      masterGainRef.current = null;
      nodesRef.current = [];
    }, 2200);
  }, [onAnalyser]);

  useEffect(() => {
    if (isPlaying) {
      start();
    } else {
      stop();
    }

    return () => {
      stop();
    };
  }, [isPlaying, start, stop]);

  return null;
}
