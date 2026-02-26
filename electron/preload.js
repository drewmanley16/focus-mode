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
    ipcRenderer.on("start-focus", callback);
    return () => ipcRenderer.removeListener("start-focus", callback);
  },
  onStopFocus: (callback) => {
    ipcRenderer.on("stop-focus", callback);
    return () => ipcRenderer.removeListener("stop-focus", callback);
  },
});
