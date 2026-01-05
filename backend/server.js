const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Import routes
const dataRoutes = require('./routes/data');
const authRoutes = require('./routes/auth');

// Initialize Express
const app = express();

// CORS Configuration for production
const allowedOrigins = [
  'http://localhost:5173',
  'http://localhost:3000',
  process.env.FRONTEND_URL
].filter(Boolean);

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl)
    if (!origin) return callback(null, true);
    
    // Allow localhost
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    
    // Allow all Vercel deployments (preview and production)
    if (origin && (
      origin.endsWith('.vercel.app') || 
      origin.includes('vercel.app')
    )) {
      return callback(null, true);
    }
    
    console.log('CORS blocked origin:', origin);
    callback(new Error('Not allowed by CORS'));
  },
  credentials: true
}));

// Log raw body for debugging bookmarks
app.use((req, res, next) => {
  if (req.path === '/api/data') {
    let data = '';
    req.on('data', chunk => {
      data += chunk;
    });
    req.on('end', () => {
      if (data.includes('"bookmarks"')) {
        console.log('\n[RAW BOOKMARKS REQUEST]:', data.substring(0, 500));
      }
    });
  }
  next();
});

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// MongoDB Connection Handler for Serverless
const MONGODB_URI = process.env.MONGODB_URI || process.env.MONGO_URI_ATLAS;

let isConnected = false;

const connectDB = async () => {
  if (!MONGODB_URI) {
    throw new Error('MONGODB_URI not found in environment variables');
  }

  if (isConnected && mongoose.connection.readyState === 1) {
    return;
  }

  try {
    mongoose.set('strictQuery', false);
    
    await mongoose.connect(MONGODB_URI, {
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      minPoolSize: 2,
    });
    
    isConnected = true;
    console.log('✓ Connected to MongoDB Atlas');
  } catch (err) {
    console.error('✗ MongoDB connection error:', err.message);
    throw err;
  }
};

// Connect immediately for cold starts
connectDB().catch(err => console.error('Initial connection failed:', err));

// Middleware to ensure DB connection before handling requests
app.use(async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (err) {
    res.status(500).json({ error: 'Database connection failed', details: err.message });
  }
});

// Routes
app.use('/api', dataRoutes);  // All data routes under /api
app.use('/api/auth', authRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ 
    status: 'online',
    message: 'Data Collection API',
    endpoints: {
      data: 'POST /api/data',
      sessions: 'GET /api/sessions',
      session_detail: 'GET /api/sessions/:session_id',
      login: 'POST /api/auth/login',
      setup: 'POST /api/auth/setup',
      update_password: 'POST /api/auth/update'
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// For serverless deployment (Vercel)
module.exports = app;

// For local development
if (require.main === module) {
  const PORT = process.env.PORT || 8080;
  app.listen(PORT, '0.0.0.0', () => {
    console.log('\n========================================');
    console.log('Data Collection Backend Server');
    console.log('========================================');
    console.log(`Server running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}`);
    console.log('========================================\n');
  });
}
