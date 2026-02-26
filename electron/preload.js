const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("electronAPI", {
  setFullscreen: (enabled) => ipcRenderer.invoke("set-fullscreen", enabled),
  onWindowBlur: (callback) => {
    ipcRenderer.on("window-blur", callback);
    return () => ipcRenderer.removeListener("window-blur", callback);
  },
  onWindowFocus: (callback) => {
    ipcRenderer.on("window-focus", callback);
    return () => ipcRenderer.removeListener("window-focus", callback);
  },
});
