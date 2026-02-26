const { app, BrowserWindow, Tray, Menu, ipcMain, nativeImage } = require("electron");
const path = require("path");

let mainWindow = null;
let tray = null;

function createTrayIcon() {
  // 22x22 template image (macOS standard menu bar size)
  // Draws a simple focus ring icon
  const size = 22;
  const canvas = `
    <svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
      <circle cx="11" cy="11" r="7" fill="none" stroke="black" stroke-width="1.5"/>
      <circle cx="11" cy="11" r="2.5" fill="black"/>
    </svg>
  `.trim();

  const encoded = Buffer.from(canvas).toString("base64");
  const image = nativeImage.createFromDataURL(`data:image/svg+xml;base64,${encoded}`);
  image.setTemplateImage(true);
  return image;
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 600,
    height: 500,
    minWidth: 400,
    minHeight: 350,
    titleBarStyle: "hiddenInset",
    trafficLightPosition: { x: 16, y: 16 },
    backgroundColor: "#000000",
    show: false,
    skipTaskbar: true,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.on("blur", () => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send("window-blur");
    }
  });

  mainWindow.on("focus", () => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send("window-focus");
    }
  });

  // Hide to tray instead of closing
  mainWindow.on("close", (e) => {
    if (!app.isQuitting) {
      e.preventDefault();
      mainWindow.hide();
    }
  });

  if (process.env.NODE_ENV === "development") {
    mainWindow.loadURL("http://localhost:3000");
  } else {
    mainWindow.loadFile(path.join(__dirname, "../out/index.html"));
  }
}

function showWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) {
    createWindow();
  }
  mainWindow.show();
  mainWindow.focus();
}

function startFocusFromTray() {
  showWindow();
  // Small delay so the renderer is ready
  setTimeout(() => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send("start-focus");
    }
  }, 300);
}

function buildTrayMenu() {
  return Menu.buildFromTemplate([
    { label: "Open Deep Focus", click: showWindow },
    { label: "Start Focus Session", click: startFocusFromTray },
    { type: "separator" },
    {
      label: "Quit",
      click: () => {
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);
}

function createTray() {
  const icon = createTrayIcon();
  tray = new Tray(icon);
  tray.setToolTip("Deep Focus");
  tray.setContextMenu(buildTrayMenu());

  tray.on("click", () => {
    if (mainWindow && mainWindow.isVisible()) {
      mainWindow.hide();
    } else {
      showWindow();
    }
  });
}

ipcMain.handle("set-fullscreen", (_event, enabled) => {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.setFullScreen(enabled);
  }
});

app.dock?.hide();

app.whenReady().then(() => {
  createTray();
  createWindow();
  // Show on first launch
  mainWindow.once("ready-to-show", () => {
    mainWindow.show();
  });
});

app.on("window-all-closed", (e) => {
  // Don't quit — tray keeps running
  e?.preventDefault?.();
});

app.on("activate", () => {
  showWindow();
});

app.on("before-quit", () => {
  app.isQuitting = true;
});
