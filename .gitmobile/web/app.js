/**
 * .gitmobile - Mobile Git Bridge Client Logic
 */

// Application State
const state = {
  currentTab: 'dashboard',
  currentFolder: '',
  authPin: localStorage.getItem('gitmobile_pin') || '',
  pinRequired: false,
  status: null,
  files: [],
  history: []
};

// DOM Elements
const elements = {
  repoNameDisplay: document.getElementById('repoNameDisplay'),
  branchName: document.getElementById('branchName'),
  syncStatusBadge: document.getElementById('syncStatusBadge'),
  refreshBtn: document.getElementById('refreshBtn'),
  behindCount: document.getElementById('behindCount'),
  aheadCount: document.getElementById('aheadCount'),
  pendingChangesCount: document.getElementById('pendingChangesCount'),
  changesBadge: document.getElementById('changesBadge'),
  statusListContainer: document.getElementById('statusListContainer'),
  quickPapersList: document.getElementById('quickPapersList'),
  papersCount: document.getElementById('papersCount'),
  fileBreadcrumbs: document.getElementById('fileBreadcrumbs'),
  fileListContainer: document.getElementById('fileListContainer'),
  commitTimelineContainer: document.getElementById('commitTimelineContainer'),
  consoleOutput: document.getElementById('consoleOutput'),
  toastContainer: document.getElementById('toastContainer'),

  // Buttons
  quickSyncBtn: document.getElementById('quickSyncBtn'),
  pullBtn: document.getElementById('pullBtn'),
  pushBtn: document.getElementById('pushBtn'),
  openCommitModalBtn: document.getElementById('openCommitModalBtn'),
  openUploadModalBtn: document.getElementById('openUploadModalBtn'),
  confirmCommitBtn: document.getElementById('confirmCommitBtn'),
  commitMessageInput: document.getElementById('commitMessageInput'),
  saveNoteBtn: document.getElementById('saveNoteBtn'),
  notePathInput: document.getElementById('notePathInput'),
  noteContentArea: document.getElementById('noteContentArea'),
  noteAutoCommit: document.getElementById('noteAutoCommit'),
  newNoteBtn: document.getElementById('newNoteBtn'),
  clearConsoleBtn: document.getElementById('clearConsoleBtn'),

  // Upload Form
  uploadForm: document.getElementById('uploadForm'),
  uploadFolderSelect: document.getElementById('uploadFolderSelect'),
  paperFileInput: document.getElementById('paperFileInput'),
  selectedFileName: document.getElementById('selectedFileName'),
  uploadAutoCommit: document.getElementById('uploadAutoCommit'),
  confirmUploadBtn: document.getElementById('confirmUploadBtn'),

  // Modals
  commitModal: document.getElementById('commitModal'),
  uploadModal: document.getElementById('uploadModal'),
  fileViewerModal: document.getElementById('fileViewerModal'),
  viewerFileName: document.getElementById('viewerFileName'),
  viewerFileContent: document.getElementById('viewerFileContent'),
  openInEditorBtn: document.getElementById('openInEditorBtn'),
  pinModal: document.getElementById('pinModal'),
  pinInput: document.getElementById('pinInput'),
  submitPinBtn: document.getElementById('submitPinBtn'),
  pinErrorMsg: document.getElementById('pinErrorMsg')
};

// =============================================================================
// Helper Functions
// =============================================================================

function showToast(message, type = 'info') {
  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  toast.textContent = message;
  elements.toastContainer.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(-10px)';
    setTimeout(() => toast.remove(), 250);
  }, 3200);
}

function logToConsole(message, type = 'info') {
  const line = document.createElement('div');
  line.className = `console-line ${type}`;
  const time = new Date().toLocaleTimeString();
  line.textContent = `[${time}] ${message}`;
  elements.consoleOutput.appendChild(line);
  elements.consoleOutput.scrollTop = elements.consoleOutput.scrollHeight;
}

async function apiRequest(endpoint, options = {}) {
  const headers = options.headers || {};
  if (state.authPin) {
    headers['x-gitmobile-pin'] = state.authPin;
  }
  
  try {
    const res = await fetch(endpoint, {
      ...options,
      headers
    });

    if (res.status === 401) {
      promptPinAuth();
      throw new Error('Authentication required');
    }

    const data = await res.json();
    return data;
  } catch (err) {
    logToConsole(`Error (${endpoint}): ${err.message}`, 'error');
    throw err;
  }
}

// =============================================================================
// Tab Switching
// =============================================================================

function switchTab(tabName) {
  state.currentTab = tabName;

  document.querySelectorAll('.tab-view').forEach(view => {
    view.classList.remove('active');
  });
  document.querySelectorAll('.nav-item').forEach(item => {
    item.classList.remove('active');
  });

  const activeView = document.getElementById(`view-${tabName}`);
  const activeNav = document.querySelector(`.nav-item[data-tab="${tabName}"]`);

  if (activeView) activeView.classList.add('active');
  if (activeNav) activeNav.classList.add('active');

  // Trigger contextual data reload
  if (tabName === 'files') loadFiles(state.currentFolder);
  if (tabName === 'history') loadHistory();
  if (tabName === 'dashboard') loadRepoStatus();
}

document.querySelectorAll('.bottom-nav .nav-item').forEach(btn => {
  btn.addEventListener('click', () => {
    const tab = btn.getAttribute('data-tab');
    switchTab(tab);
  });
});

// =============================================================================
// Modals
// =============================================================================

function openModal(modal) {
  modal.classList.add('active');
}

function closeModals() {
  document.querySelectorAll('.modal').forEach(m => {
    if (m.id !== 'pinModal' || !state.pinRequired) {
      m.classList.remove('active');
    }
  });
}

function openUploadModal() {
  elements.uploadFolderSelect.value = state.currentFolder || 'papers';
  openModal(elements.uploadModal);
}

// =============================================================================
// PIN Authentication Flow
// =============================================================================

async function checkConfig() {
  try {
    const res = await fetch('/api/config-info');
    const info = await res.json();
    state.pinRequired = info.pinRequired;
    elements.repoNameDisplay.textContent = info.repoName || 'Repository';

    if (info.pinRequired) {
      if (!state.authPin) {
        promptPinAuth();
      } else {
        // Validate saved PIN
        verifySavedPin();
      }
    } else {
      loadRepoStatus();
      loadQuickPapers();
    }
  } catch (err) {
    logToConsole('Could not fetch bridge configuration', 'error');
  }
}

function promptPinAuth() {
  elements.pinModal.classList.add('active');
  elements.pinInput.focus();
}

async function verifySavedPin() {
  try {
    const res = await fetch('/api/verify-pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin: state.authPin })
    });
    const data = await res.json();
    if (data.success) {
      elements.pinModal.classList.remove('active');
      loadRepoStatus();
      loadQuickPapers();
    } else {
      promptPinAuth();
    }
  } catch (_) {
    promptPinAuth();
  }
}

elements.submitPinBtn.addEventListener('click', async () => {
  const pin = elements.pinInput.value.trim();
  if (!pin) return;

  try {
    const res = await fetch('/api/verify-pin', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ pin })
    });
    const data = await res.json();

    if (data.success) {
      state.authPin = pin;
      localStorage.setItem('gitmobile_pin', pin);
      elements.pinModal.classList.remove('active');
      elements.pinErrorMsg.textContent = '';
      showToast('Unlocked successfully', 'success');
      loadRepoStatus();
      loadQuickPapers();
    } else {
      elements.pinErrorMsg.textContent = 'Incorrect PIN';
    }
  } catch (err) {
    elements.pinErrorMsg.textContent = 'Connection error';
  }
});

// =============================================================================
// Repository Status & Dashboard
// =============================================================================

async function loadRepoStatus() {
  try {
    elements.refreshBtn.style.transform = 'rotate(180deg)';
    setTimeout(() => elements.refreshBtn.style.transform = 'none', 300);

    const data = await apiRequest('/api/status');
    if (!data.success) return;

    state.status = data.status;
    const s = data.status;

    // Header info
    elements.branchName.textContent = s.branch;
    
    if (s.isClean) {
      elements.syncStatusBadge.textContent = 'Clean';
      elements.syncStatusBadge.className = 'status-badge clean';
      elements.changesBadge.textContent = 'Clean';
      elements.changesBadge.className = 'badge';
    } else {
      const totalChanges = s.counts.modified + s.counts.staged + s.counts.untracked;
      elements.syncStatusBadge.textContent = `${totalChanges} Unsaved`;
      elements.syncStatusBadge.className = 'status-badge dirty';
      elements.changesBadge.textContent = `${totalChanges} changes`;
      elements.changesBadge.className = 'badge badge-accent';
    }

    // Counters
    elements.behindCount.textContent = `${s.behind} behind`;
    elements.aheadCount.textContent = `${s.ahead} ahead`;
    
    const totalPending = s.counts.modified + s.counts.staged + s.counts.untracked;
    elements.pendingChangesCount.textContent = `${totalPending} changes`;

    // Render Working Tree list
    renderWorkingTree(s.files, s.isClean);
  } catch (err) {
    elements.syncStatusBadge.textContent = 'Offline / Error';
  }
}

function renderWorkingTree(files, isClean) {
  elements.statusListContainer.innerHTML = '';

  if (isClean) {
    elements.statusListContainer.innerHTML = `
      <div class="empty-state">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
        <p>Working tree clean. All changes committed.</p>
      </div>
    `;
    return;
  }

  // Staged files
  files.staged.forEach(f => {
    const item = document.createElement('div');
    item.className = 'status-item';
    item.innerHTML = `<span>${f.file}</span><span class="status-code A">STAGED</span>`;
    elements.statusListContainer.appendChild(item);
  });

  // Modified files
  files.modified.forEach(f => {
    const item = document.createElement('div');
    item.className = 'status-item';
    item.innerHTML = `<span>${f.file}</span><span class="status-code M">MODIFIED</span>`;
    elements.statusListContainer.appendChild(item);
  });

  // Untracked files
  files.untracked.forEach(f => {
    const item = document.createElement('div');
    item.className = 'status-item';
    item.innerHTML = `<span>${f}</span><span class="status-code U">UNTRACKED</span>`;
    elements.statusListContainer.appendChild(item);
  });
}

// =============================================================================
// Git Operations: Sync, Pull, Push, Commit
// =============================================================================

elements.quickSyncBtn.addEventListener('click', async () => {
  try {
    elements.quickSyncBtn.disabled = true;
    elements.quickSyncBtn.textContent = 'Syncing...';
    logToConsole('Starting One-Tap Quick Sync...', 'info');

    const res = await apiRequest('/api/sync', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: '' })
    });

    if (res.logs) {
      res.logs.forEach(l => logToConsole(l, 'success'));
    }
    showToast('Sync complete!', 'success');
    loadRepoStatus();
    loadQuickPapers();
  } catch (err) {
    showToast('Sync error: ' + (err.message || 'Failed'), 'error');
  } finally {
    elements.quickSyncBtn.disabled = false;
    elements.quickSyncBtn.innerHTML = `
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
        <path d="M21.5 2v6h-6M21.34 15.57a10 10 0 1 1-.57-8.38l5.67-5.67"/>
      </svg>
      Sync Repository
    `;
  }
});

elements.pullBtn.addEventListener('click', async () => {
  try {
    logToConsole('Executing git pull...', 'info');
    showToast('Pulling changes...', 'info');
    const res = await apiRequest('/api/pull', { method: 'POST' });
    logToConsole(res.result.stdout || 'Up to date.', 'success');
    showToast('Pull finished', 'success');
    loadRepoStatus();
  } catch (err) {
    showToast('Pull failed: ' + err.message, 'error');
  }
});

elements.pushBtn.addEventListener('click', async () => {
  try {
    logToConsole('Executing git push...', 'info');
    showToast('Pushing commits...', 'info');
    const res = await apiRequest('/api/push', { method: 'POST' });
    logToConsole(res.result.stdout || 'Push completed.', 'success');
    showToast('Push finished', 'success');
    loadRepoStatus();
  } catch (err) {
    showToast('Push failed: ' + err.message, 'error');
  }
});

elements.openCommitModalBtn.addEventListener('click', () => {
  elements.commitMessageInput.value = '';
  openModal(elements.commitModal);
});

elements.confirmCommitBtn.addEventListener('click', async () => {
  const message = elements.commitMessageInput.value.trim();
  if (!message) {
    showToast('Please enter a commit message', 'error');
    return;
  }

  try {
    logToConsole(`Committing changes: "${message}"...`, 'info');
    const res = await apiRequest('/api/commit', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message })
    });
    logToConsole(res.result.stdout, 'success');
    showToast('Committed successfully', 'success');
    closeModals();
    loadRepoStatus();
  } catch (err) {
    showToast('Commit failed: ' + err.message, 'error');
  }
});

// =============================================================================
// Files & Research Papers
// =============================================================================

async function loadQuickPapers() {
  try {
    const res = await apiRequest('/api/files?folder=papers');
    if (!res.success) return;

    elements.papersCount.textContent = `${res.files.length} items`;
    elements.quickPapersList.innerHTML = '';

    if (res.files.length === 0) {
      elements.quickPapersList.innerHTML = '<p class="subtext">No papers uploaded yet.</p>';
      return;
    }

    res.files.forEach(f => {
      const card = document.createElement('div');
      card.className = 'paper-card';
      const isPdf = f.name.endsWith('.pdf');
      card.innerHTML = `
        <div class="paper-title">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="${isPdf ? '#ef4444' : '#6366f1'}" stroke-width="2">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/>
          </svg>
          <span>${f.name}</span>
        </div>
        <span class="file-size">${formatBytes(f.size)}</span>
      `;
      card.addEventListener('click', () => {
        if (f.name.endsWith('.md') || f.name.endsWith('.txt')) {
          viewFile(f.path);
        }
      });
      elements.quickPapersList.appendChild(card);
    });
  } catch (_) {}
}

async function loadFiles(folder = '') {
  state.currentFolder = folder;
  renderBreadcrumbs(folder);

  try {
    elements.fileListContainer.innerHTML = '<div class="loading-spinner">Loading files...</div>';
    const res = await apiRequest(`/api/files?folder=${encodeURIComponent(folder)}`);
    if (!res.success) return;

    elements.fileListContainer.innerHTML = '';
    if (res.files.length === 0) {
      elements.fileListContainer.innerHTML = '<div class="empty-state"><p>Folder is empty.</p></div>';
      return;
    }

    res.files.forEach(item => {
      const row = document.createElement('div');
      row.className = 'file-row';

      const iconSvg = item.isDirectory
        ? '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#f59e0b" stroke-width="2"><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/></svg>'
        : item.name.endsWith('.pdf')
          ? '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#ef4444" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>'
          : '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#94a3b8" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>';

      row.innerHTML = `
        <div class="file-main">
          <div class="file-icon">${iconSvg}</div>
          <span class="file-name">${item.name}</span>
        </div>
        <span class="file-size">${item.isDirectory ? 'folder' : formatBytes(item.size)}</span>
      `;

      row.addEventListener('click', () => {
        if (item.isDirectory) {
          loadFiles(item.path);
        } else {
          viewFile(item.path);
        }
      });

      elements.fileListContainer.appendChild(row);
    });
  } catch (err) {
    elements.fileListContainer.innerHTML = '<div class="empty-state"><p>Could not load files.</p></div>';
  }
}

function renderBreadcrumbs(folder) {
  elements.fileBreadcrumbs.innerHTML = '';
  const rootSpan = document.createElement('span');
  rootSpan.className = `crumb ${folder === '' ? 'active' : ''}`;
  rootSpan.textContent = 'root';
  rootSpan.onclick = () => loadFiles('');
  elements.fileBreadcrumbs.appendChild(rootSpan);

  if (!folder) return;

  const parts = folder.split('/');
  let accumulated = '';

  parts.forEach((p, index) => {
    accumulated += (accumulated ? '/' : '') + p;
    const sep = document.createElement('span');
    sep.textContent = '/';
    sep.style.color = 'var(--text-muted)';
    elements.fileBreadcrumbs.appendChild(sep);

    const crumb = document.createElement('span');
    const isLast = index === parts.length - 1;
    crumb.className = `crumb ${isLast ? 'active' : ''}`;
    crumb.textContent = p;
    const thisPath = accumulated;
    if (!isLast) crumb.onclick = () => loadFiles(thisPath);
    elements.fileBreadcrumbs.appendChild(crumb);
  });
}

async function viewFile(filePath) {
  try {
    const res = await apiRequest(`/api/file?path=${encodeURIComponent(filePath)}`);
    if (!res.success) return;

    elements.viewerFileName.textContent = filePath;
    elements.viewerFileContent.textContent = res.content;
    elements.openInEditorBtn.onclick = () => {
      elements.notePathInput.value = filePath;
      elements.noteContentArea.value = res.content;
      closeModals();
      switchTab('notes');
    };
    openModal(elements.fileViewerModal);
  } catch (err) {
    showToast('Cannot preview binary file directly', 'info');
  }
}

// File Upload Handler
elements.paperFileInput.addEventListener('change', () => {
  if (elements.paperFileInput.files.length > 0) {
    elements.selectedFileName.textContent = elements.paperFileInput.files[0].name;
  }
});

elements.openUploadModalBtn.addEventListener('click', openUploadModal);

elements.confirmUploadBtn.addEventListener('click', async (e) => {
  e.preventDefault();
  const file = elements.paperFileInput.files[0];
  if (!file) {
    showToast('Please choose a file', 'error');
    return;
  }

  const folder = elements.uploadFolderSelect.value;
  const autoCommit = elements.uploadAutoCommit.checked;

  const formData = new FormData();
  formData.append('file', file);
  formData.append('autoCommit', autoCommit ? 'true' : 'false');
  formData.append('commitMessage', `feat: add document ${file.name}`);

  try {
    elements.confirmUploadBtn.disabled = true;
    elements.confirmUploadBtn.textContent = 'Uploading...';
    logToConsole(`Uploading ${file.name} to ${folder}/...`, 'info');

    const headers = {};
    if (state.authPin) headers['x-gitmobile-pin'] = state.authPin;

    const res = await fetch(`/api/upload?folder=${encodeURIComponent(folder)}`, {
      method: 'POST',
      headers,
      body: formData
    });

    const data = await res.json();
    if (data.success) {
      showToast(`Uploaded ${data.filename}`, 'success');
      logToConsole(`Saved file: ${data.path}`, 'success');
      closeModals();
      loadFiles(folder);
      loadQuickPapers();
      loadRepoStatus();
    } else {
      showToast('Upload failed: ' + data.error, 'error');
    }
  } catch (err) {
    showToast('Upload failed: ' + err.message, 'error');
  } finally {
    elements.confirmUploadBtn.disabled = false;
    elements.confirmUploadBtn.textContent = 'Upload to Repo';
  }
});

// =============================================================================
// Notes Editor
// =============================================================================

elements.newNoteBtn.addEventListener('click', () => {
  const timestamp = new Date().toISOString().slice(0, 10);
  elements.notePathInput.value = `notes/note-${timestamp}.md`;
  elements.noteContentArea.value = `# Research Note - ${timestamp}\n\n## Abstract\n\n## Insights & Takeaways\n- \n`;
  elements.noteContentArea.focus();
});

elements.saveNoteBtn.addEventListener('click', async () => {
  const filePath = elements.notePathInput.value.trim();
  const content = elements.noteContentArea.value;
  const autoCommit = elements.noteAutoCommit.checked;

  if (!filePath) {
    showToast('Specify a file path', 'error');
    return;
  }

  try {
    logToConsole(`Saving note: ${filePath}...`, 'info');
    const res = await apiRequest('/api/note', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        filePath,
        content,
        autoCommit,
        commitMessage: `docs: update research note ${filePath}`
      })
    });

    if (res.success) {
      showToast('Note saved & staged!', 'success');
      logToConsole(`Saved note ${filePath}`, 'success');
      loadRepoStatus();
    }
  } catch (err) {
    showToast('Save failed: ' + err.message, 'error');
  }
});

// =============================================================================
// Commit History Timeline
// =============================================================================

async function loadHistory() {
  try {
    elements.commitTimelineContainer.innerHTML = '<div class="loading-spinner">Loading timeline...</div>';
    const res = await apiRequest('/api/history?count=20');
    if (!res.success) return;

    elements.commitTimelineContainer.innerHTML = '';
    if (res.history.length === 0) {
      elements.commitTimelineContainer.innerHTML = '<div class="empty-state"><p>No commit history found.</p></div>';
      return;
    }

    res.history.forEach(item => {
      const el = document.createElement('div');
      el.className = 'timeline-item';
      el.innerHTML = `
        <div class="timeline-bullet"></div>
        <div class="timeline-card">
          <div class="timeline-subject">${escapeHtml(item.subject)}</div>
          <div class="timeline-meta">
            <span class="commit-hash">${item.shortHash}</span>
            <span>by ${escapeHtml(item.author)}</span>
            <span>• ${item.relativeDate}</span>
          </div>
        </div>
      `;
      elements.commitTimelineContainer.appendChild(el);
    });
  } catch (err) {
    elements.commitTimelineContainer.innerHTML = '<div class="empty-state"><p>Could not load history.</p></div>';
  }
}

// =============================================================================
// Console & Utilities
// =============================================================================

elements.clearConsoleBtn.addEventListener('click', () => {
  elements.consoleOutput.innerHTML = '';
  logToConsole('Console cleared.', 'info');
});

elements.refreshBtn.addEventListener('click', () => {
  loadRepoStatus();
  loadQuickPapers();
  showToast('Refreshed status', 'info');
});

function formatBytes(bytes) {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function escapeHtml(str) {
  if (!str) return '';
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

// Initialize on page load
window.addEventListener('DOMContentLoaded', () => {
  checkConfig();
});
