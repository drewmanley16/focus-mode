"use client";

import { useEffect, useRef } from "react";

interface AudioReactiveBackgroundProps {
  analyser: AnalyserNode | null;
  active: boolean;
}

interface Blob {
  x: number;
  y: number;
  baseRadius: number;
  phase: number;
  speed: number;
  driftX: number;
  driftY: number;
}

function createBlobs(count: number, w: number, h: number): Blob[] {
  return Array.from({ length: count }, () => ({
    x: w * (0.2 + Math.random() * 0.6),
    y: h * (0.2 + Math.random() * 0.6),
    baseRadius: 80 + Math.random() * 160,
    phase: Math.random() * Math.PI * 2,
    speed: 0.0003 + Math.random() * 0.0006,
    driftX: (Math.random() - 0.5) * 0.15,
    driftY: (Math.random() - 0.5) * 0.15,
  }));
}

export default function AudioReactiveBackground({
  analyser,
  active,
}: AudioReactiveBackgroundProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const blobsRef = useRef<Blob[]>([]);
  const rafRef = useRef<number>(0);
  const energyRef = useRef(0);
  const opacityRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    let w = window.innerWidth;
    let h = window.innerHeight;

    const resize = () => {
      w = window.innerWidth;
      h = window.innerHeight;
      canvas.width = w * dpr;
      canvas.height = h * dpr;
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      blobsRef.current = createBlobs(5, w, h);
    };

    resize();
    window.addEventListener("resize", resize);

    const dataArray = new Uint8Array(analyser?.frequencyBinCount ?? 128);

    const draw = (time: number) => {
      const targetOpacity = active ? 1 : 0;
      opacityRef.current += (targetOpacity - opacityRef.current) * 0.02;

      if (opacityRef.current < 0.001 && !active) {
        ctx.clearRect(0, 0, w, h);
        rafRef.current = requestAnimationFrame(draw);
        return;
      }

      if (analyser) {
        analyser.getByteFrequencyData(dataArray);
        let sum = 0;
        for (let i = 0; i < dataArray.length; i++) {
          sum += dataArray[i];
        }
        const avg = sum / dataArray.length / 255;
        energyRef.current += (avg - energyRef.current) * 0.08;
      } else {
        energyRef.current *= 0.95;
      }

      const energy = energyRef.current;

      ctx.clearRect(0, 0, w, h);

      const blobs = blobsRef.current;
      for (const blob of blobs) {
        blob.phase += blob.speed * 16;
        blob.x += blob.driftX;
        blob.y += blob.driftY;

        if (blob.x < -200) blob.x = w + 200;
        if (blob.x > w + 200) blob.x = -200;
        if (blob.y < -200) blob.y = h + 200;
        if (blob.y > h + 200) blob.y = -200;

        const breathe = Math.sin(blob.phase) * 0.15;
        const pulse = energy * 1.2;
        const radius = blob.baseRadius * (1 + breathe + pulse);

        const gradient = ctx.createRadialGradient(
          blob.x,
          blob.y,
          0,
          blob.x,
          blob.y,
          radius
        );

        const baseAlpha = 0.012 + energy * 0.025;
        const alpha = baseAlpha * opacityRef.current;

        gradient.addColorStop(0, `rgba(255, 255, 255, ${alpha})`);
        gradient.addColorStop(0.5, `rgba(255, 255, 255, ${alpha * 0.4})`);
        gradient.addColorStop(1, "rgba(255, 255, 255, 0)");

        ctx.fillStyle = gradient;
        ctx.beginPath();
        ctx.arc(blob.x, blob.y, radius, 0, Math.PI * 2);
        ctx.fill();
      }

      // Subtle noise-synced vignette pulse
      const vignetteAlpha = (0.03 + energy * 0.06) * opacityRef.current;
      const vignette = ctx.createRadialGradient(
        w / 2, h / 2, w * 0.1,
        w / 2, h / 2, w * 0.7
      );
      vignette.addColorStop(0, `rgba(255, 255, 255, ${vignetteAlpha * 0.3})`);
      vignette.addColorStop(1, "rgba(0, 0, 0, 0)");
      ctx.fillStyle = vignette;
      ctx.fillRect(0, 0, w, h);

      rafRef.current = requestAnimationFrame(draw);
    };

    rafRef.current = requestAnimationFrame(draw);

    return () => {
      cancelAnimationFrame(rafRef.current);
      window.removeEventListener("resize", resize);
    };
  }, [analyser, active]);

  return (
    <canvas
      ref={canvasRef}
      className="pointer-events-none absolute inset-0 z-0"
    />
  );
}
