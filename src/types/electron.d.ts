interface ElectronAPI {
  setFullscreen: (enabled: boolean) => Promise<void>;
  onWindowBlur: (callback: () => void) => () => void;
  onWindowFocus: (callback: () => void) => () => void;
}

interface Window {
  electronAPI?: ElectronAPI;
}
