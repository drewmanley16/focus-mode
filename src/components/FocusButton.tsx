"use client";

import { motion } from "framer-motion";

interface FocusButtonProps {
  onActivate: () => void;
}

export default function FocusButton({ onActivate }: FocusButtonProps) {
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

      <motion.p
        className="text-sm font-light tracking-wider text-white/25"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.5, duration: 1 }}
      >
        45 minute session
      </motion.p>
    </motion.div>
  );
}
