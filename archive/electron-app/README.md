# Deep Focus — Electron (Archived)

This folder contains the **archived** Electron + Next.js version of Deep Focus.

The app has been superseded by the native Swift macOS app (`DeepFocus/` at repo root), which is now the production build distributed via TestFlight and the Mac App Store.

## What's here

- **electron/** — Main process, preload, tray, DND/media integration
- **src/** — Next.js frontend (React, Framer Motion, ambient audio)
- **public/** — Static assets
- **assets/** — App icon, DMG background

## To run (for reference)

```bash
npm install
npm run electron:dev
```

## To build (for reference)

```bash
npm run electron:build
```

Requires Next.js build output in `out/` and `assets/icon.icns`.
