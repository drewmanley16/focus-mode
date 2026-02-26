"use client";

import { motion } from "framer-motion";

const DURATION_OPTIONS = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];

interface FocusButtonProps {
  duration: number;
  onDurationChange: (minutes: number) => void;
  onActivate: () => void;
}

export default function FocusButton({
  duration,
  onDurationChange,
  onActivate,
}: FocusButtonProps) {
  const currentIndex = DURATION_OPTIONS.indexOf(duration);

  const prev = () => {
    const next = currentIndex > 0 ? currentIndex - 1 : DURATION_OPTIONS.length - 1;
    onDurationChange(DURATION_OPTIONS[next]);
  };

  const next = () => {
    const nextIdx = currentIndex < DURATION_OPTIONS.length - 1 ? currentIndex + 1 : 0;
    onDurationChange(DURATION_OPTIONS[nextIdx]);
  };

  const label =
    duration >= 60
      ? `${duration / 60} hour${duration > 60 ? "s" : ""} session`
      : `${duration} minute session`;

  return (
    <motion.div
      className="flex flex-col items-center gap-8"
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
    >
      <motion.button
        onClick={onActivate}
        className="relative flex h-52 w-52 items-center justify-center rounded-full border border-white/[0.08] bg-white/[0.03] text-white/80 transition-colors hover:bg-white/[0.06] hover:text-white focus:outline-none"
        animate={{
          scale: [1, 1.03, 1],
        }}
        transition={{
          duration: 4,
          repeat: Infinity,
          ease: "easeInOut",
        }}
        whileTap={{ scale: 0.97 }}
      >
        <span className="text-lg font-light tracking-widest uppercase">
          Enter Focus
        </span>
      </motion.button>

      <motion.div
        className="flex items-center gap-5"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.5, duration: 1 }}
      >
        <button
          onClick={prev}
          className="flex h-7 w-7 items-center justify-center rounded-full text-white/20 transition-colors hover:text-white/50 focus:outline-none"
          aria-label="Decrease duration"
        >
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M9 3L5 7L9 11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>

        <p className="min-w-[140px] text-center text-sm font-light tracking-wider text-white/25">
          {label}
        </p>

        <button
          onClick={next}
          className="flex h-7 w-7 items-center justify-center rounded-full text-white/20 transition-colors hover:text-white/50 focus:outline-none"
          aria-label="Increase duration"
        >
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M5 3L9 7L5 11" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
        </button>
      </motion.div>
    </motion.div>
  );
}
