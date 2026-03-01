const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("electronAPI", {
  setFullscreen: (enabled) => ipcRenderer.invoke("set-fullscreen", enabled),
  enterFocusMode: () => ipcRenderer.invoke("enter-focus-mode"),
  exitFocusMode: () => ipcRenderer.invoke("exit-focus-mode"),
  onWindowBlur: (callback) => {
    ipcRenderer.on("window-blur", callback);
    return () => ipcRenderer.removeListener("window-blur", callback);
  },
  onWindowFocus: (callback) => {
    ipcRenderer.on("window-focus", callback);
    return () => ipcRenderer.removeListener("window-focus", callback);
  },
  onStartFocus: (callback) => {
    const handler = (_event, minutes) => callback(minutes);
    ipcRenderer.on("start-focus", handler);
    return () => ipcRenderer.removeListener("start-focus", handler);
  },
  onStopFocus: (callback) => {
    ipcRenderer.on("stop-focus", callback);
    return () => ipcRenderer.removeListener("stop-focus", callback);
  },
  onAppQuitting: (callback) => {
    ipcRenderer.on("app-quitting", callback);
    return () => ipcRenderer.removeListener("app-quitting", callback);
  },
});
