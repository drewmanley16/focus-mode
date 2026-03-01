const { app, BrowserWindow, Tray, Menu, ipcMain, nativeImage } = require("electron");
const { exec } = require("child_process");
const path = require("path");

let mainWindow = null;
let tray = null;
let focusActive = false;

// ---------------------------------------------------------------------------
// macOS Do Not Disturb
// ---------------------------------------------------------------------------

const isMAS = process.mas || process.windowsStore;

function enableDND() {
  if (isMAS) return;
  const cmds = [
    'defaults -currentHost write com.apple.notificationcenterui doNotDisturb -boolean true',
    'defaults -currentHost write com.apple.notificationcenterui doNotDisturbDate -date "$(date -u +\\"%Y-%m-%dT%H:%M:%SZ\\")"',
    'killall ControlCenter 2>/dev/null; killall NotificationCenter 2>/dev/null; true',
  ];
  exec(cmds.join(" && "), () => {});
}

function disableDND() {
  if (isMAS) return;
  const cmds = [
    'defaults -currentHost write com.apple.notificationcenterui doNotDisturb -boolean false',
    'defaults -currentHost delete com.apple.notificationcenterui doNotDisturbDate 2>/dev/null; true',
    'killall ControlCenter 2>/dev/null; killall NotificationCenter 2>/dev/null; true',
  ];
  exec(cmds.join(" && "), () => {});
}

// ---------------------------------------------------------------------------
// Pause / resume media
// ---------------------------------------------------------------------------

function pauseMedia() {
  if (isMAS) return;
  const players = [
    { name: "Music", cmd: 'if application "Music" is running then tell application "Music" to pause' },
    { name: "Spotify", cmd: 'if application "Spotify" is running then tell application "Spotify" to pause' },
    { name: "TV", cmd: 'if application "TV" is running then tell application "TV" to pause' },
  ];
  for (const p of players) {
    exec(`osascript -e '${p.cmd}'`, () => {});
  }
}

// ---------------------------------------------------------------------------
// Tray icon
// ---------------------------------------------------------------------------

function createTrayIcon(active) {
  const size = 22;
  const fillOrStroke = active
    ? `<circle cx="11" cy="11" r="7" fill="black"/><circle cx="11" cy="11" r="2.5" fill="white"/>`
    : `<circle cx="11" cy="11" r="7" fill="none" stroke="black" stroke-width="1.5"/><circle cx="11" cy="11" r="2.5" fill="black"/>`;

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">${fillOrStroke}</svg>`;
  const image = nativeImage.createFromDataURL(
    `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`
  );
  image.setTemplateImage(true);
  return image;
}

function updateTrayIcon() {
  if (tray) {
    tray.setImage(createTrayIcon(focusActive));
  }
}

// ---------------------------------------------------------------------------
// Window
// ---------------------------------------------------------------------------

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

function startFocusFromTray(minutes) {
  showWindow();
  setTimeout(() => {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.webContents.send("start-focus", minutes);
    }
  }, 300);
}

// ---------------------------------------------------------------------------
// Tray menu
// ---------------------------------------------------------------------------

function buildTrayMenu() {
  if (focusActive) {
    return Menu.buildFromTemplate([
      { label: "Focusing…", enabled: false },
      { label: "End Session", click: () => {
        if (mainWindow && !mainWindow.isDestroyed()) {
          mainWindow.webContents.send("stop-focus");
        }
      }},
      { type: "separator" },
      { label: "Quit", click: () => { app.isQuitting = true; app.quit(); } },
    ]);
  }

  const durations = [5, 10, 15, 20, 25, 30, 45, 60, 90, 120];
  const durationSubmenu = durations.map((m) => ({
    label: m >= 60 ? `${m / 60} hour${m > 60 ? "s" : ""}` : `${m} minutes`,
    click: () => startFocusFromTray(m),
  }));

  return Menu.buildFromTemplate([
    { label: "Open Deep Focus", click: showWindow },
    { label: "Lock In", submenu: durationSubmenu },
    { type: "separator" },
    { label: "Quit", click: () => { app.isQuitting = true; app.quit(); } },
  ]);
}

function refreshTray() {
  updateTrayIcon();
  if (tray) {
    tray.setContextMenu(buildTrayMenu());
  }
}

function createTray() {
  tray = new Tray(createTrayIcon(false));
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

// ---------------------------------------------------------------------------
// IPC handlers
// ---------------------------------------------------------------------------

ipcMain.handle("set-fullscreen", (_event, enabled) => {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.setFullScreen(enabled);
  }
});

ipcMain.handle("enter-focus-mode", () => {
  focusActive = true;
  enableDND();
  pauseMedia();
  refreshTray();
});

ipcMain.handle("exit-focus-mode", () => {
  focusActive = false;
  disableDND();
  refreshTray();
});

// ---------------------------------------------------------------------------
// App lifecycle
// ---------------------------------------------------------------------------

app.dock?.hide();

app.whenReady().then(() => {
  createTray();
  createWindow();
  mainWindow.once("ready-to-show", () => {
    mainWindow.show();
  });
});

app.on("window-all-closed", (e) => {
  e?.preventDefault?.();
});

app.on("activate", () => {
  showWindow();
});

app.on("before-quit", () => {
  app.isQuitting = true;
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send("stop-focus");
    mainWindow.webContents.send("app-quitting");
  }
  if (focusActive) {
    disableDND();
  }
});
