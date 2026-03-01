"use client";

import { useCallback } from "react";

export function useFullscreen() {
  const enter = useCallback(() => {
    if (window.electronAPI) {
      window.electronAPI.setFullscreen(true);
    } else if (document.documentElement.requestFullscreen) {
      document.documentElement.requestFullscreen().catch(() => {});
    }
  }, []);

  const exit = useCallback(() => {
    if (window.electronAPI) {
      window.electronAPI.setFullscreen(false);
    } else if (document.fullscreenElement) {
      document.exitFullscreen().catch(() => {});
    }
  }, []);

  return { enter, exit };
}
