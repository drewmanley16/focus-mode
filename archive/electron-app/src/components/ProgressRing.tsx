"use client";

import { motion } from "framer-motion";

interface ProgressRingProps {
  progress: number; // 0 to 1
  size?: number;
  strokeWidth?: number;
  isComplete?: boolean;
}

export default function ProgressRing({
  progress,
  size = 280,
  strokeWidth = 3,
  isComplete = false,
}: ProgressRingProps) {
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - progress);

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg
        width={size}
        height={size}
        viewBox={`0 0 ${size} ${size}`}
        className="rotate-[-90deg]"
      >
        {/* Background track */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="rgba(255, 255, 255, 0.06)"
          strokeWidth={strokeWidth}
        />

        {/* Progress arc */}
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={isComplete ? "rgba(255, 255, 255, 0.9)" : "rgba(255, 255, 255, 0.35)"}
          strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          initial={false}
          animate={{
            strokeDashoffset,
            stroke: isComplete
              ? "rgba(255, 255, 255, 0.9)"
              : "rgba(255, 255, 255, 0.35)",
          }}
          transition={{ duration: 0.5, ease: "linear" }}
        />
      </svg>

      {/* Completion glow */}
      {isComplete && (
        <motion.div
          className="absolute inset-0 rounded-full"
          initial={{ opacity: 0 }}
          animate={{
            opacity: [0, 0.4, 0],
          }}
          transition={{
            duration: 3,
            repeat: Infinity,
            ease: "easeInOut",
          }}
          style={{
            boxShadow: "0 0 60px 20px rgba(255, 255, 255, 0.08)",
          }}
        />
      )}
    </div>
  );
}
