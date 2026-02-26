"use client";

import { useEffect, useRef, useCallback } from "react";

interface AmbientAudioControllerProps {
  isPlaying: boolean;
  volume?: number;
  onAnalyser?: (analyser: AnalyserNode | null) => void;
}

function generateBrownNoise(ctx: AudioContext): AudioBufferSourceNode {
  const bufferSize = 2 * ctx.sampleRate;
  const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
  const data = buffer.getChannelData(0);

  let lastOut = 0;
  for (let i = 0; i < bufferSize; i++) {
    const white = Math.random() * 2 - 1;
    data[i] = (lastOut + 0.02 * white) / 1.02;
    lastOut = data[i];
    data[i] *= 3.5;
  }

  const source = ctx.createBufferSource();
  source.buffer = buffer;
  source.loop = true;
  source.start(0);
  return source;
}

export default function AmbientAudioController({
  isPlaying,
  volume = 0.15,
  onAnalyser,
}: AmbientAudioControllerProps) {
  const ctxRef = useRef<AudioContext | null>(null);
  const gainRef = useRef<GainNode | null>(null);
  const sourceRef = useRef<AudioBufferSourceNode | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);

  const start = useCallback(() => {
    if (ctxRef.current) return;

    const ctx = new AudioContext();
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0, ctx.currentTime);
    gain.gain.linearRampToValueAtTime(volume, ctx.currentTime + 2);

    const analyser = ctx.createAnalyser();
    analyser.fftSize = 256;
    analyser.smoothingTimeConstant = 0.85;

    const source = generateBrownNoise(ctx);
    source.connect(analyser);
    analyser.connect(gain);
    gain.connect(ctx.destination);

    ctxRef.current = ctx;
    gainRef.current = gain;
    sourceRef.current = source;
    analyserRef.current = analyser;

    onAnalyser?.(analyser);
  }, [volume, onAnalyser]);

  const stop = useCallback(() => {
    const ctx = ctxRef.current;
    const gain = gainRef.current;

    if (!ctx || !gain) return;

    onAnalyser?.(null);

    gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 1.5);

    setTimeout(() => {
      ctx.close();
      ctxRef.current = null;
      gainRef.current = null;
      sourceRef.current = null;
      analyserRef.current = null;
    }, 1600);
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
