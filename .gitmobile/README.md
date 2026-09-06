# .gitmobile — Mobile Git Control Center & Bridge

`.gitmobile` is a portable, drop-in module designed to sit inside any Git repository. It hosts a secure, lightweight local Node.js/Express service providing a touch-optimized mobile UI/UX.

With **Termux** on Android, you can securely connect to this module over an encrypted SSH port tunnel, allowing you to manage your repository—pulling, staging, committing, pushing, uploading research papers, and writing notes—completely from your phone with single-tap controls.

---

## Architecture (Stage 1: Termux SSH Bridge)

```
[ Your PC / Host Machine ]                           [ Android Phone (Termux) ]
  ┌──────────────────────────────────────────────┐     ┌────────────────────────────────────┐
  │ Repository Root                              │     │ 1. Termux opens SSH tunnel:        │
  │  ├── papers/ & notes/                        │     │    ssh -N -L 3000:127.0.0.1:3000   │
  │  └── .gitmobile/                             │     │    user@pc-ip                      │
  │       ├── server/ (Express + Git Ops)        │     │                                    │
  │       │    └── Binds strictly to 127.0.0.1   │     │ 2. Phone Browser / PWA:            │
  │       └── web/ (Mobile Web Client)           │     │    http://localhost:3000           │
  └──────────────────────▲───────────────────────┘     └─────────────────▲──────────────────┘
                         │                                               │
                         └───────────────── Encrypted Tunnel ────────────┘
```

---

## Quickstart

### 1. Setup on Your Computer
From the root of your repository:
```bash
cd .gitmobile
node setup.js       # Runs the interactive wizard and gives tailored connection commands
```
Or start directly:
* **Windows:** Double-click `start.bat` or run `.\start.bat`
* **Linux / Mac:** `./start.sh`

The server will bind to `127.0.0.1:3000`.

---

### 2. Connect From Your Phone (Via Termux)

1. Open **Termux** on your Android phone.
2. Ensure `openssh` is installed:
   ```bash
   pkg update && pkg install openssh
   ```
3. Run the one-line port forwarding command:
   ```bash
   ssh -N -L 3000:127.0.0.1:3000 <your-pc-username>@<your-pc-ip>
   ```
   *(Replace `<your-pc-username>` and `<your-pc-ip>` with your computer's local IP, printed by `setup.js`)*.
4. Open your phone's browser (Chrome, Firefox, Brave) and navigate to:
   ```
   http://localhost:3000
   ```
5. **Tip:** In Chrome, tap the menu (⋮) -> **"Add to Home screen"** to install it as an app icon with no browser address bar!

---

## Key Features & Research Use Case

### 1. One-Tap Mobile Quick Sync
* Pulls remote changes from GitHub.
* Checks if you made edits on your phone (e.g. uploaded a paper or edited notes).
* Commits changes with an automated timestamp.
* Pushes cleanly back to GitHub.

### 2. Research Paper & Document Uploader
* Tap **"Add Paper"** on mobile.
* Select a PDF or document directly from your phone's downloads or files.
* Stores the file inside `papers/` and optionally creates an immediate Git commit.

### 3. Markdown Research Notes Editor
* Write abstracts, reading notes, and formulas directly on your phone.
* Auto-save & auto-commit to the `notes/` directory.

### 4. Git Activity Console & Commit History
* View recent commits with short hashes, authors, and timestamps.
* Live console log streaming all `git` stdout/stderr outputs so you always know what happened.

---

## Security & Local Data Protection

* **Localhost-Only Binding:** The Express server binds strictly to `127.0.0.1`. It is inaccessible to any other device on your Wi-Fi unless routed through an authenticated SSH tunnel.
* **Encrypted SSH Tunnel:** All network traffic between your phone and your computer is secured with military-grade SSH encryption.
* **Path Traversal Sandboxing:** All file reads, writes, and uploads are validated against the repository root (`path.resolve`) to prevent directory traversal (`../../`).
* **Optional Master PIN:** You can set a 4-digit PIN in `setup.js` to prevent unauthorized access even if someone picks up your unlocked phone.

---

## REST API Reference

| Endpoint | Method | Description |
|---|---|---|
| `/api/status` | GET | Current branch, sync status, ahead/behind counts, changed files |
| `/api/sync` | POST | Atomic Quick Sync: Pull -> Auto-commit -> Push |
| `/api/pull` | POST | Pull latest remote commits |
| `/api/push` | POST | Push local commits to remote |
| `/api/commit` | POST | Stage all and commit with custom message `{ message }` |
| `/api/files` | GET | List directory contents safely `?folder=papers` |
| `/api/file` | GET | Read text file safely `?path=notes/note.md` |
| `/api/note` | POST | Create or update markdown note `{ filePath, content, autoCommit }` |
| `/api/upload` | POST | Multipart upload for papers and documents |
| `/api/history` | GET | View recent Git commits `?count=20` |
