# QEMS Portable PC Server

## One-click use

Double-click **Start QEMS.bat**. It uses **runtime/node.exe**, starts the server in the background, waits until it is ready, and opens QEMS in your default browser. No Node.js installation, npm install, sign-in screen, or setup form is required in the default open-access mode. Running the batch again opens the existing server instead of creating another instance.

Other PCs and phones on the same private network can open the server PC’s address, for example **http://192.168.100.29:3100**. The current addresses are listed in **logs/server.log** and the launcher output. That address can change after changing Wi-Fi or restarting the router; a DHCP reservation keeps it stable. Keep the server PC powered on and awake. If Windows requests network access, allow Node.js on **Private networks**. Windows firewall permissions and Wi-Fi client isolation can still prevent connections; the batch cannot bypass network policies.

**All devices open as Shared Workspace with management/edit access.** This intentionally removes account sign-in. Leadman, checker, and exception password confirmations remain part of their workflows. Server audit entries include the connecting device IP; actions made through the shared account are not proof of an individual user’s identity. Use this mode only on your trusted LAN. Do not forward this port to the Internet. HTTP is unencrypted; HTTPS can be configured using the environment variables below.

## Everything stays in this folder

```text
qems-server/
  Start QEMS.bat       Start server and open app
  Stop QEMS.bat        Stop server before moving/copying
  index.html          App and standard templates
  server.mjs          Node.js server
  server-config.json  Open/password mode, host, port
  seed.json           Imported workbook baseline
  sync-core.cjs       Concurrent-edit conflict handling
  start.ps1           Portable launcher helper
  Stop QEMS.ps1       Stop helper
  runtime/
    node.exe          Included Windows portable Node.js runtime
  data/
    qems.sqlite       Shared records, users, uploaded forms and answers
    backups/          Recovery snapshots
  logs/
    server.log
    server-error.log
```

Copy this **whole folder** to another Windows PC to move the server. First run **Stop QEMS.bat**. Keep the **data** folder and all SQLite/WAL sidecar files together. Never run two different server PCs against the same database file on a network share. Other client devices only need a browser; they do not need a folder copy or Node.js. The included runtime is Windows x64, Node.js 24. Replace runtime/node.exe with a compatible Node.js 24+ portable runtime for a different Windows architecture. The launcher checks runtime/node.exe first, then runtime/node/node.exe, nodejs/node.exe, and finally an installed Node executable.

The launcher uses paths relative to its own folder and works from folders containing spaces. It does not depend on Codex or this user profile. No data is written outside the app folder by the server under its default configuration.

## Transfer latest data from the original browser app

Browser-local edits in the original file-based app are not automatically available to the server. Open the old app, click **Backup**, then use **Restore backup** in the server app before other users begin work. Keep the exported backup. Restoring updates the workspace for every device. The open-access account is retained automatically during restore. Imported baseline CQM and Material Inspection records are already included.

## Simultaneous editing and recovery

Different records and different fields can be edited at the same time. If two devices change the same field, the second save is rejected rather than overwriting the first. Export unsaved work before reloading after a conflict. CQM record IDs are allocated centrally. Other devices refresh approximately every four seconds when no form/field is being edited. Filters and navigation stay local to each browser. Save operations wait for the server; large form libraries can cause a short pause.

Use **Backup** in the app for a portable JSON backup. Hourly recovery snapshots, triggered after changes, are kept under data/backups (latest 24 retained). Stop the server before copying the full data folder. Rebuilding app files does not erase that folder.

## Configuration

Edit **server-config.json** while the server is stopped. The defaults are accessMode=open, host=0.0.0.0, port=3100. To restore account login, set accessMode to password and ensure a registered active Admin has a configured password first. A fresh database in password mode uses localhost-only administrator setup. Stop/start the server after changes.

Advanced environment overrides: PORT, QEMS_HOST, QEMS_DATA_DIR, QEMS_ACCESS_MODE. HTTPS: QEMS_PFX and QEMS_PFX_PASSWORD, or QEMS_TLS_KEY and QEMS_TLS_CERT. Client devices must trust the certificate. Setting QEMS_DATA_DIR deliberately places runtime data outside this portable folder.

This is a LAN testing release; complete production and workflow permission reviews before wider deployment.


## GitHub development and workflow

Repository: **JCADurante/QEMS** (private).

- `src/`: server, shared-save transport and portable launcher source.
- `app/index.template.html`: app UI and standard form templates; contains a synthetic example record, no operational logs.
- `fixtures/seed.json`: sample baseline/configuration for builds and tests, no live records or user passwords.
- `scripts/build.mjs`: creates `dist/qems-server` without touching the current deployment.
- `tests/`: server concurrency/authentication and portable startup tests.
- `.github/workflows/ci.yml`: automatically checks, tests and packages the Windows portable app on pushes to main and pull requests. It can also be run manually in GitHub Actions.

Use Node.js 24+ and run `npm run check`, `npm run build`, `npm test`, and `npm run test:portable` on Windows. No npm dependencies are required. Download the tested ZIP from the successful GitHub Actions run. This workflow does not automatically deploy to your private PC.

**Never commit data/, logs/, runtime/, dist/, .env files, certificates, the current index.html or the live seed.json.** Git tracks source and synthetic fixtures only. The production workbook baseline is persisted under `data/baseline.json`; it is injected into the served app so a code update does not remove imported records. To update the deployed app, stop QEMS, back up data/, and copy the tested package files while retaining the existing data/ folder. A fresh build starts with sample data until a workspace backup is restored.
