const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_EXPIRES_IN = '6h'; // 6 hours token expiration

// POST /api/auth/login - Admin login with simple password
router.post('/login', async (req, res) => {
  try {
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({ error: 'Password is required' });
    }

    // Get admin password from DB
    const admin = await Admin.findOne();

    if (!admin) {
      return res.status(500).json({ error: 'Admin not configured. Please set admin password.' });
    }

    // Compare password
    const isMatch = await bcrypt.compare(password, admin.password);

    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid password' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { adminId: admin._id, role: 'admin' },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.json({ 
      success: true,
      message: 'Login successful',
      token: token
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.admin = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
};

// GET /api/auth/verify - Verify token validity
router.get('/verify', verifyToken, (req, res) => {
  res.json({ 
    success: true,
    valid: true,
    admin: req.admin
  });
});

// POST /api/auth/setup - Initial admin password setup
router.post('/setup', async (req, res) => {
  try {
    const { password } = req.body;

    if (!password) {
      return res.status(400).json({ error: 'Password is required' });
    }

    // Check if admin already exists
    const existingAdmin = await Admin.findOne();
    if (existingAdmin) {
      return res.status(400).json({ error: 'Admin already configured. Use /update to change password.' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create admin
    const admin = new Admin({ password: hashedPassword });
    await admin.save();

    res.json({ 
      success: true,
      message: 'Admin password configured successfully'
    });

  } catch (error) {
    console.error('Setup error:', error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/auth/update - Update admin password
router.post('/update', async (req, res) => {
  try {
    const { old_password, new_password } = req.body;

    if (!old_password || !new_password) {
      return res.status(400).json({ error: 'Both old and new passwords are required' });
    }

    const admin = await Admin.findOne();

    if (!admin) {
      return res.status(500).json({ error: 'Admin not configured' });
    }

    // Verify old password
    const isMatch = await bcrypt.compare(old_password, admin.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid old password' });
    }

    // Hash and save new password
    admin.password = await bcrypt.hash(new_password, 10);
    await admin.save();

    res.json({ 
      success: true,
      message: 'Password updated successfully'
    });

  } catch (error) {
    console.error('Update password error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
