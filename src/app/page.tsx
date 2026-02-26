"use client";

import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import FocusButton from "@/components/FocusButton";
import FocusTimer from "@/components/FocusTimer";
import AmbientAudioController from "@/components/AmbientAudioController";
import { useFullscreen } from "@/hooks/useFullscreen";
import { useCursorHide } from "@/hooks/useCursorHide";
import { useTabVisibility } from "@/hooks/useTabVisibility";

type AppState = "idle" | "focusing" | "complete";

export default function Home() {
  const [state, setState] = useState<AppState>("idle");
  const [durationMinutes, setDurationMinutes] = useState(45);
  const fullscreen = useFullscreen();
  const isTabVisible = useTabVisibility(state === "focusing");

  useCursorHide(state === "focusing");

  const handleActivate = useCallback(() => {
    setState("focusing");
    fullscreen.enter();
  }, [fullscreen]);

  const handleComplete = useCallback(() => {
    setState("complete");
    playCompletionSound();
  }, []);

  const handleExit = useCallback(() => {
    setState("idle");
    fullscreen.exit();
  }, [fullscreen]);

  useEffect(() => {
    if (state === "focusing") {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [state]);

  const isFocusing = state === "focusing" || state === "complete";

  return (
    <main className="relative flex h-screen w-screen items-center justify-center overflow-hidden bg-black">
      <motion.div
        className="pointer-events-none absolute inset-0"
        animate={{
          background: isFocusing
            ? "radial-gradient(ellipse at center, rgba(255,255,255,0.02) 0%, transparent 70%)"
            : "radial-gradient(ellipse at center, transparent 0%, transparent 70%)",
        }}
        transition={{ duration: 2, ease: "easeInOut" }}
      />

      <AnimatePresence>
        {isFocusing && !isTabVisible && (
          <motion.div
            className="absolute inset-0 z-50 flex items-center justify-center bg-black/80"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.5 }}
          >
            <p className="text-lg font-extralight tracking-widest text-white/40">
              Welcome back. Stay focused.
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      <AnimatePresence mode="wait">
        {state === "idle" ? (
          <FocusButton
            key="button"
            duration={durationMinutes}
            onDurationChange={setDurationMinutes}
            onActivate={handleActivate}
          />
        ) : (
          <FocusTimer
            key="timer"
            duration={durationMinutes * 60}
            onExit={handleExit}
            onComplete={handleComplete}
          />
        )}
      </AnimatePresence>

      <AnimatePresence>
        {state === "focusing" && (
          <motion.button
            onClick={handleExit}
            className="absolute bottom-8 right-8 text-xs font-light tracking-widest text-white/15 uppercase transition-colors hover:text-white/40 focus:outline-none"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ delay: 1, duration: 1 }}
          >
            Exit
          </motion.button>
        )}
      </AnimatePresence>

      <AmbientAudioController isPlaying={state === "focusing"} />
    </main>
  );
}

function playCompletionSound() {
  try {
    const ctx = new AudioContext();
    const now = ctx.currentTime;

    const frequencies = [523.25, 659.25, 783.99];
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 3);
    gain.connect(ctx.destination);

    frequencies.forEach((freq, i) => {
      const osc = ctx.createOscillator();
      osc.type = "sine";
      osc.frequency.setValueAtTime(freq, now + i * 0.15);
      osc.connect(gain);
      osc.start(now + i * 0.15);
      osc.stop(now + 3);
    });

    setTimeout(() => ctx.close(), 4000);
  } catch {
    // Audio not available
  }
}
