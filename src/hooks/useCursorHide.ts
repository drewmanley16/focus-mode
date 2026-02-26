"use client";

import { useEffect, useRef, useCallback } from "react";

export function useCursorHide(active: boolean, delay = 3000) {
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const hideCursor = useCallback(() => {
    document.body.classList.add("hide-cursor");
  }, []);

  const showCursor = useCallback(() => {
    document.body.classList.remove("hide-cursor");
  }, []);

  const resetTimer = useCallback(() => {
    showCursor();
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(hideCursor, delay);
  }, [delay, hideCursor, showCursor]);

  useEffect(() => {
    if (!active) {
      showCursor();
      if (timerRef.current) clearTimeout(timerRef.current);
      return;
    }

    resetTimer();

    const handleMove = () => resetTimer();
    window.addEventListener("mousemove", handleMove);
    window.addEventListener("mousedown", handleMove);

    return () => {
      window.removeEventListener("mousemove", handleMove);
      window.removeEventListener("mousedown", handleMove);
      showCursor();
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [active, resetTimer, showCursor]);
}
