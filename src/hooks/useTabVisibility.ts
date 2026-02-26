"use client";

import { useState, useEffect } from "react";

export function useTabVisibility(active: boolean) {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    if (!active) {
      setIsVisible(true);
      return;
    }

    const handleChange = () => {
      setIsVisible(!document.hidden);
    };

    document.addEventListener("visibilitychange", handleChange);
    return () => document.removeEventListener("visibilitychange", handleChange);
  }, [active]);

  return isVisible;
}
