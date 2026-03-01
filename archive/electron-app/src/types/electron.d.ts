interface ElectronAPI {
  setFullscreen: (enabled: boolean) => Promise<void>;
  enterFocusMode: () => Promise<void>;
  exitFocusMode: () => Promise<void>;
  onWindowBlur: (callback: () => void) => () => void;
  onWindowFocus: (callback: () => void) => () => void;
  onStartFocus: (callback: (minutes?: number) => void) => () => void;
  onStopFocus: (callback: () => void) => () => void;
  onAppQuitting: (callback: () => void) => () => void;
}

interface Window {
  electronAPI?: ElectronAPI;
}
