"use client";

import { useState, useEffect } from "react";

export function useTabVisibility(active: boolean) {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    if (!active) {
      setIsVisible(true);
      return;
    }

    const handleVisible = () => setIsVisible(true);
    const handleHidden = () => setIsVisible(false);

    const cleanups: (() => void)[] = [];

    if (window.electronAPI) {
      cleanups.push(window.electronAPI.onWindowBlur(handleHidden));
      cleanups.push(window.electronAPI.onWindowFocus(handleVisible));
    }

    const handleVisibilityChange = () => {
      if (document.hidden) handleHidden();
      else handleVisible();
    };

    document.addEventListener("visibilitychange", handleVisibilityChange);
    window.addEventListener("focus", handleVisible);
    window.addEventListener("blur", handleHidden);

    return () => {
      cleanups.forEach((fn) => fn());
      document.removeEventListener("visibilitychange", handleVisibilityChange);
      window.removeEventListener("focus", handleVisible);
      window.removeEventListener("blur", handleHidden);
    };
  }, [active]);

  return isVisible;
}
