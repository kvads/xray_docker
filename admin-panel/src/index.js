const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const { v4: uuidv4 } = require('uuid');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database setup
const db = new sqlite3.Database('/app/data/users.db');

db.serialize(() => {
    db.run(`CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_used DATETIME,
        is_active BOOLEAN DEFAULT 1
    )`);
});

// Routes
app.post('/api/users', (req, res) => {
    const { email } = req.body;
    const id = uuidv4();
    
    db.run('INSERT INTO users (id, email) VALUES (?, ?)', [id, email], function(err) {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        
        // Update Xray config
        updateXrayConfig(id);
        
        res.json({
            id,
            email,
            created_at: new Date().toISOString()
        });
    });
});

app.get('/api/users', (req, res) => {
    db.all('SELECT * FROM users', [], (err, rows) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        res.json(rows);
    });
});

app.delete('/api/users/:id', (req, res) => {
    const { id } = req.params;
    
    db.run('DELETE FROM users WHERE id = ?', [id], function(err) {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        
        // Update Xray config
        updateXrayConfig();
        
        res.json({ message: 'User deleted successfully' });
    });
});

// Helper function to update Xray config
function updateXrayConfig(newUserId = null) {
    const configPath = '/etc/xray/config.json';
    
    try {
        const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
        
        // Get all active users from database
        db.all('SELECT id FROM users WHERE is_active = 1', [], (err, rows) => {
            if (err) {
                console.error('Error getting users:', err);
                return;
            }
            
            // Update clients in all inbounds
            config.inbounds.forEach(inbound => {
                if (inbound.protocol === 'vless') {
                    inbound.settings.clients = rows.map(row => ({
                        id: row.id,
                        flow: "xtls-rprx-vision"
                    }));
                }
            });
            
            // Write updated config
            fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
            
            // Reload Xray
            // Note: In production, you might want to use a more robust way to reload Xray
            try {
                fs.writeFileSync('/tmp/xray.reload', '');
            } catch (err) {
                console.error('Error triggering Xray reload:', err);
            }
        });
    } catch (err) {
        console.error('Error updating Xray config:', err);
    }
}

app.listen(port, () => {
    console.log(`Admin panel listening at http://localhost:${port}`);
}); 