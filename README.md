# Research Papers & Notes Repository

A structured research paper repository managed seamlessly via desktop and mobile using **[.gitmobile](file:///.gitmobile/)**.

## Structure
* `papers/` - PDF papers, research documents, and preprints.
* `notes/` - Markdown summaries, analysis, and reading logs.
* `.gitmobile/` - Portable Mobile Git Bridge module for managing this repository from your phone via Termux.

## Getting Started on Mobile
1. Start the bridge on your computer:
   ```bash
   cd .gitmobile
   npm start
   ```
2. Tunnel from your phone via Termux:
   ```bash
   ssh -N -L 3000:127.0.0.1:3000 your-pc-username@your-pc-ip
   ```
3. Open `http://localhost:3000` in your mobile browser to sync, upload papers, and write notes with one tap.
