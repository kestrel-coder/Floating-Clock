const { app, BrowserWindow, desktopCapturer, nativeTheme, screen } = require('electron');

const { execFile } = require('child_process');
const fs       = require("fs");
const path     = require('path');
const { promisify } = require('util');
const cfg_file = path.join(__dirname, 'clock.json');
const isDebug  = false;
const execFileAsync = promisify(execFile);
const THEME_SYNC_INTERVAL_MS = 3000;
const FULLSCREEN_DARK_THRESHOLD = 110;

const FRONTMOST_FULLSCREEN_SCRIPT = `
tell application "System Events"
    set frontApp to first application process whose frontmost is true
    try
        set appWindow to first window of frontApp whose value of attribute "AXMain" is true
    on error
        try
            set appWindow to first window of frontApp
        on error
            return "unknown"
        end try
    end try
    try
        set fsValue to value of attribute "AXFullScreen" of appWindow
        if fsValue is true then
            return "true"
        end if
        return "false"
    on error
        return "unknown"
    end try
end tell
`;

let win;
var opts = {};
let themeSyncInterval = null;
let themeSyncInProgress = false;
let nativeThemeListener = null;
let lastAppliedThemeMode = null;
let keepOnTopInterval = null;

var winOpts = { 
    width: 340, 
    height: 120, 
    alwaysOnTop: true, 
    icon: path.join(__dirname, "sound", 'clock.png'),
    titleBarStyle: 'hiddenInset',
    webPreferences: {
        nodeIntegration: true,
        contextIsolation: false
    }
}

const baseContentSize = {
    width: winOpts.width,
    height: winOpts.height
};
const baseAspectRatio = baseContentSize.width / baseContentSize.height;

if (!isDebug) {
    winOpts['resizable'] = true;
} else {
    winOpts['height'] = 400; 

}

// Load CFG
if (fs.existsSync(cfg_file)) {
    if (opts) {
        opts = JSON.parse( fs.readFileSync(cfg_file, "utf8") );
        if ("x" in opts) winOpts["x"] = parseInt(opts.x);
        if ("y" in opts) winOpts["y"] = parseInt(opts.y);
    }
}

// Update opts with window pos
function updateWinPos(sender) {
    opts["x"] = sender.getPosition()[0];
    opts["y"] = sender.getPosition()[1]-25;
}

function updateWindowScale(sender) {
    if (!sender || sender.isDestroyed()) return;

    const [width, height] = sender.getContentSize();
    if (width <= 0 || height <= 0) return;

    const widthScale = width / baseContentSize.width;
    const heightScale = height / baseContentSize.height;
    const zoomFactor = Math.max(0.4, Math.min(widthScale, heightScale));

    sender.webContents.setZoomFactor(zoomFactor);
}

function getSystemThemeMode() {
    return nativeTheme.shouldUseDarkColors ? 'dark' : 'light';
}

async function isFrontmostFullscreenMacOS() {
    if (process.platform !== 'darwin') return false;

    try {
        const { stdout } = await execFileAsync('osascript', ['-e', FRONTMOST_FULLSCREEN_SCRIPT], {
            timeout: 1200
        });
        return stdout.trim().toLowerCase() === 'true';
    } catch (err) {
        return false;
    }
}

async function getScreenBrightnessThemeMode(sender) {
    if (!sender || sender.isDestroyed()) return null;

    try {
        const targetDisplay = screen.getDisplayMatching(sender.getBounds());
        const sources = await desktopCapturer.getSources({
            types: ['screen'],
            thumbnailSize: { width: 128, height: 72 },
            fetchWindowIcons: false
        });

        if (!sources || sources.length === 0) return null;

        let source = sources.find(function(item) {
            return String(item.display_id) === String(targetDisplay.id);
        });
        if (!source) source = sources[0];
        if (!source || source.thumbnail.isEmpty()) return null;

        const bitmap = source.thumbnail.toBitmap();
        if (!bitmap || bitmap.length < 4) return null;

        let totalLuminance = 0;
        let sampleCount = 0;

        // Bitmap is BGRA; sample every 4th pixel for lower CPU cost.
        for (let i = 0; i < bitmap.length; i += 16) {
            const b = bitmap[i];
            const g = bitmap[i + 1];
            const r = bitmap[i + 2];

            totalLuminance += (0.2126 * r) + (0.7152 * g) + (0.0722 * b);
            sampleCount += 1;
        }

        if (sampleCount === 0) return null;

        const avgLuminance = totalLuminance / sampleCount;
        return avgLuminance < FULLSCREEN_DARK_THRESHOLD ? 'dark' : 'light';
    } catch (err) {
        return null;
    }
}

async function resolveThemeMode(sender) {
    const systemMode = getSystemThemeMode();

    if (process.platform !== 'darwin') return systemMode;

    const isFullscreen = await isFrontmostFullscreenMacOS();
    if (!isFullscreen) return systemMode;

    const sampledMode = await getScreenBrightnessThemeMode(sender);
    return sampledMode || systemMode;
}

function pushThemeMode(sender, mode) {
    if (!sender || sender.isDestroyed()) return;
    if (mode !== 'dark' && mode !== 'light') return;
    if (mode === lastAppliedThemeMode) return;

    lastAppliedThemeMode = mode;
    sender.webContents.send('theme-override', mode);
}

async function syncThemeMode(sender) {
    if (!sender || sender.isDestroyed()) return;
    if (themeSyncInProgress) return;

    themeSyncInProgress = true;
    try {
        const mode = await resolveThemeMode(sender);
        pushThemeMode(sender, mode);
    } finally {
        themeSyncInProgress = false;
    }
}

function stopThemeSync() {
    if (themeSyncInterval) {
        clearInterval(themeSyncInterval);
        themeSyncInterval = null;
    }
    if (nativeThemeListener) {
        nativeTheme.removeListener('updated', nativeThemeListener);
        nativeThemeListener = null;
    }
    lastAppliedThemeMode = null;
}

function stopKeepOnTopSync() {
    if (keepOnTopInterval) {
        clearInterval(keepOnTopInterval);
        keepOnTopInterval = null;
    }
}

function startKeepOnTopSync(sender) {
    stopKeepOnTopSync();

    keepOnTopInterval = setInterval(function() {
        if (!sender || sender.isDestroyed()) return;
        sender.setAlwaysOnTop(true, 'screen-saver');
        updateWinPos(sender);
    }, 250);
}

function startThemeSync(sender) {
    stopThemeSync();

    nativeThemeListener = function() {
        syncThemeMode(sender);
    };
    nativeTheme.on('updated', nativeThemeListener);

    syncThemeMode(sender);
    themeSyncInterval = setInterval(function() {
        syncThemeMode(sender);
    }, THEME_SYNC_INTERVAL_MS);
}

function createWindow () {
    win = new BrowserWindow(winOpts);
    win.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
    win.setAlwaysOnTop(true, 'screen-saver');
    win.setMenu(null);
    win.setAspectRatio(baseAspectRatio);
    win.loadFile('index.html')
    win.webContents.on('did-finish-load', function() {
        updateWindowScale(win);
        startThemeSync(win);
        startKeepOnTopSync(win);
    });
    win.on('resize', function() {
        updateWindowScale(win);
    });
    win.on('focus', function() {
        syncThemeMode(win);
    });
    
    if (isDebug) {
        win.webContents.openDevTools()
    }

    win.on('closed', () => {
        stopKeepOnTopSync();
        stopThemeSync();
        fs.writeFileSync(cfg_file, JSON.stringify(opts));
        win = null
    })
}

app.on('ready', createWindow)

app.on('window-all-closed', () => {
    if (process.platform !== 'darwin') {
        win = null
        app.quit()
    }
})

app.on('activate', () => {
    if (win === null) {
        createWindow()
    }
})
