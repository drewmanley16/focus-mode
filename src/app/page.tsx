"use client";

import { useState, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import FocusButton from "@/components/FocusButton";
import FocusTimer from "@/components/FocusTimer";
import AmbientAudioController from "@/components/AmbientAudioController";
import AudioReactiveBackground from "@/components/AudioReactiveBackground";
import { useFullscreen } from "@/hooks/useFullscreen";
import { useCursorHide } from "@/hooks/useCursorHide";
import { useTabVisibility } from "@/hooks/useTabVisibility";

type AppState = "idle" | "focusing" | "complete";

export default function Home() {
  const [state, setState] = useState<AppState>("idle");
  const [durationMinutes, setDurationMinutes] = useState(45);
  const [analyser, setAnalyser] = useState<AnalyserNode | null>(null);
  const fullscreen = useFullscreen();
  const isTabVisible = useTabVisibility(state === "focusing");

  useCursorHide(state === "focusing");

  const handleActivate = useCallback(() => {
    setState("focusing");
    fullscreen.enter();
    window.electronAPI?.enterFocusMode();
  }, [fullscreen]);

  const handleComplete = useCallback(() => {
    setState("complete");
    playCompletionSound();
    window.electronAPI?.exitFocusMode();
  }, []);

  const handleExit = useCallback(() => {
    setState("idle");
    fullscreen.exit();
    window.electronAPI?.exitFocusMode();
  }, [fullscreen]);

  const handleAnalyser = useCallback((node: AnalyserNode | null) => {
    setAnalyser(node);
  }, []);

  // Listen for tray commands
  useEffect(() => {
    if (!window.electronAPI) return;
    const cleanupStart = window.electronAPI.onStartFocus(() => {
      handleActivate();
    });
    const cleanupStop = window.electronAPI.onStopFocus(() => {
      handleExit();
    });
    return () => {
      cleanupStart();
      cleanupStop();
    };
  }, [handleActivate, handleExit]);

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
      {/* Draggable titlebar region for frameless window */}
      <div className="fixed top-0 left-0 right-0 z-40 h-12 [-webkit-app-region:drag]" />

      {/* Audio-reactive background */}
      <AudioReactiveBackground analyser={analyser} active={isFocusing} />

      {/* Top-right start button (idle only) */}
      <AnimatePresence>
        {state === "idle" && (
          <motion.button
            onClick={handleActivate}
            className="fixed top-4 right-4 z-50 flex h-9 items-center gap-2 rounded-full border border-white/[0.08] bg-white/[0.04] px-4 text-xs font-light tracking-widest text-white/40 uppercase [-webkit-app-region:no-drag] transition-colors hover:bg-white/[0.08] hover:text-white/70 focus:outline-none"
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
          >
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none" className="opacity-60">
              <path d="M4 2.5L9 6L4 9.5V2.5Z" fill="currentColor" />
            </svg>
            Start
          </motion.button>
        )}
      </AnimatePresence>

      {/* Tab-away / window blur overlay */}
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

      {/* Main content */}
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

      {/* Exit button during focus */}
      <AnimatePresence>
        {state === "focusing" && (
          <motion.button
            onClick={handleExit}
            className="absolute bottom-8 right-8 z-10 text-xs font-light tracking-widest text-white/15 uppercase transition-colors hover:text-white/40 focus:outline-none"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ delay: 1, duration: 1 }}
          >
            Exit
          </motion.button>
        )}
      </AnimatePresence>

      <AmbientAudioController
        isPlaying={state === "focusing"}
        onAnalyser={handleAnalyser}
      />
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
