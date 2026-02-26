"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import ProgressRing from "./ProgressRing";

const FOCUS_DURATION = 45 * 60; // 45 minutes in seconds

interface FocusTimerProps {
  onExit: () => void;
  onComplete: () => void;
}

export default function FocusTimer({ onExit, onComplete }: FocusTimerProps) {
  const [elapsed, setElapsed] = useState(0);
  const [isComplete, setIsComplete] = useState(false);
  const startTimeRef = useRef<number>(Date.now());
  const rafRef = useRef<number>(0);

  const tick = useCallback(() => {
    const now = Date.now();
    const secondsElapsed = (now - startTimeRef.current) / 1000;

    if (secondsElapsed >= FOCUS_DURATION) {
      setElapsed(FOCUS_DURATION);
      setIsComplete(true);
      onComplete();
      return;
    }

    setElapsed(secondsElapsed);
    rafRef.current = requestAnimationFrame(tick);
  }, [onComplete]);

  useEffect(() => {
    startTimeRef.current = Date.now();
    rafRef.current = requestAnimationFrame(tick);

    return () => {
      cancelAnimationFrame(rafRef.current);
    };
  }, [tick]);

  const remaining = Math.max(0, FOCUS_DURATION - elapsed);
  const minutes = Math.floor(remaining / 60);
  const seconds = Math.floor(remaining % 60);
  const progress = elapsed / FOCUS_DURATION;

  const timeString = `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;

  return (
    <motion.div
      className="flex flex-col items-center gap-10"
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 1, ease: [0.22, 1, 0.36, 1] }}
    >
      <div className="relative flex items-center justify-center">
        <ProgressRing progress={progress} isComplete={isComplete} />

        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <AnimatePresence mode="wait">
            {isComplete ? (
              <motion.div
                key="complete"
                className="flex flex-col items-center gap-3"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, ease: "easeOut" }}
              >
                <p className="text-xl font-extralight tracking-widest text-white/90">
                  Session Complete
                </p>
              </motion.div>
            ) : (
              <motion.p
                key="timer"
                className="text-5xl font-extralight tracking-[0.2em] text-white/80 tabular-nums"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                transition={{ duration: 0.5 }}
              >
                {timeString}
              </motion.p>
            )}
          </AnimatePresence>
        </div>
      </div>

      <AnimatePresence>
        {isComplete && (
          <motion.button
            onClick={onExit}
            className="text-sm font-light tracking-widest text-white/30 uppercase transition-colors hover:text-white/60 focus:outline-none"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            transition={{ delay: 0.5, duration: 0.8 }}
          >
            Start Again
          </motion.button>
        )}
      </AnimatePresence>
    </motion.div>
  );
}
