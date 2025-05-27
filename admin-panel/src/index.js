const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const QRCode = require('qrcode');
const moment = require('moment');
const winston = require('winston');

const app = express();
const port = process.env.PORT || 3000;

// Logger setup
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: '/app/data/error.log', level: 'error' }),
        new winston.transports.File({ filename: '/app/data/combined.log' })
    ]
});

if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple()
    }));
}

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../frontend/build')));

// Database setup
const db = new sqlite3.Database('/app/data/users.db');

db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_used DATETIME,
        is_active BOOLEAN DEFAULT 1,
        traffic_up BIGINT DEFAULT 0,
        traffic_down BIGINT DEFAULT 0
    )`);

    db.run(`CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
    )`);
});

// Routes
app.post('/api/users', async (req, res) => {
    const { email } = req.body;
    const id = uuidv4();
    
    try {
        await db.run('INSERT INTO users (id, email) VALUES (?, ?)', [id, email]);
        
        // Update Xray config
        await updateXrayConfig(id);
        
        // Generate QR code
        const config = generateClientConfig(id);
        const qrCode = await QRCode.toDataURL(config);
        
        res.json({
            id,
            email,
            created_at: new Date().toISOString(),
            qr_code: qrCode,
            config
        });
    } catch (err) {
        logger.error('Error creating user:', err);
        res.status(400).json({ error: err.message });
    }
});

app.get('/api/users', (req, res) => {
    db.all('SELECT * FROM users', [], (err, rows) => {
        if (err) {
            logger.error('Error getting users:', err);
            return res.status(400).json({ error: err.message });
        }
        res.json(rows);
    });
});

app.get('/api/users/:id/config', async (req, res) => {
    const { id } = req.params;
    
    try {
        const config = generateClientConfig(id);
        const qrCode = await QRCode.toDataURL(config);
        
        res.json({
            config,
            qr_code: qrCode
        });
    } catch (err) {
        logger.error('Error generating config:', err);
        res.status(400).json({ error: err.message });
    }
});

app.delete('/api/users/:id', async (req, res) => {
    const { id } = req.params;
    
    try {
        await db.run('DELETE FROM users WHERE id = ?', [id]);
        await updateXrayConfig();
        res.json({ message: 'User deleted successfully' });
    } catch (err) {
        logger.error('Error deleting user:', err);
        res.status(400).json({ error: err.message });
    }
});

app.get('/api/settings', (req, res) => {
    db.all('SELECT * FROM settings', [], (err, rows) => {
        if (err) {
            logger.error('Error getting settings:', err);
            return res.status(400).json({ error: err.message });
        }
        res.json(rows.reduce((acc, row) => ({ ...acc, [row.key]: row.value }), {}));
    });
});

app.post('/api/settings', async (req, res) => {
    const settings = req.body;
    
    try {
        for (const [key, value] of Object.entries(settings)) {
            await db.run('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [key, value]);
        }
        await updateXrayConfig();
        res.json({ message: 'Settings updated successfully' });
    } catch (err) {
        logger.error('Error updating settings:', err);
        res.status(400).json({ error: err.message });
    }
});

// Helper functions
function generateClientConfig(userId) {
    const settings = {
        server: process.env.DOMAIN,
        port: 443,
        protocol: 'vless',
        uuid: userId,
        flow: 'xtls-rprx-vision',
        security: 'reality',
        sni: 'github.com',
        fp: 'chrome',
        pbk: process.env.REALITY_PUBLIC_KEY,
        sid: process.env.REALITY_SHORT_ID,
        alpn: ['h2', 'http/1.1']
    };
    
    return `vless://${userId}@${settings.server}:${settings.port}?type=tcp&security=${settings.security}&sni=${settings.sni}&fp=${settings.fp}&pbk=${settings.pbk}&sid=${settings.sid}&flow=${settings.flow}&alpn=${settings.alpn.join(',')}#Xray-Reality`;
}

async function updateXrayConfig(newUserId = null) {
    const configPath = '/etc/xray/config.json';
    
    try {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        
        // Get all active users from database
        const users = await new Promise((resolve, reject) => {
            db.all('SELECT id FROM users WHERE is_active = 1', [], (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
        
        // Update clients in all inbounds
        config.inbounds.forEach(inbound => {
            if (inbound.protocol === 'vless') {
                inbound.settings.clients = users.map(row => ({
                    id: row.id,
                    flow: "xtls-rprx-vision"
                }));
            }
        });
        
        // Write updated config
        fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
        
        // Reload Xray
        try {
            fs.writeFileSync('/tmp/xray.reload', '');
            logger.info('Xray config updated and reloaded');
        } catch (err) {
            logger.error('Error triggering Xray reload:', err);
        }
    } catch (err) {
        logger.error('Error updating Xray config:', err);
        throw err;
    }
}

// Serve React app
app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../frontend/build/index.html'));
});

app.listen(port, () => {
    logger.info(`Admin panel listening at http://localhost:${port}`);
}); 