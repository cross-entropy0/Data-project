# Data Collection Project - AI Agent Instructions

## Project Overview
Full-stack data collection system with Node.js/Express/MongoDB backend and React/Vite frontend. Receives data from Windows collectors, stores in MongoDB Atlas, and displays via authenticated dashboard.

## Architecture

### Backend (`backend/`)
- **Stack**: Express 5.x, Mongoose 9.x, JWT authentication
- **Entry point**: `server.js` (dual-mode: serverless export + local listen)
- **Database**: MongoDB Atlas with session-based data storage
- **Authentication**: JWT tokens (6-hour expiration) via bcryptjs + jsonwebtoken

### Frontend (`Frontend/`)
- **Stack**: React 19, Vite 7, Tailwind CSS 3, React Router 7
- **Build**: Vite with ESM modules
- **Styling**: Tailwind utility classes throughout
- **Icons**: lucide-react package

### Data Flow
1. External collectors POST to `/api/data` with session_id + data type
2. Backend creates/updates Session documents in MongoDB
3. Session marked "complete" when ≥5/8 data types collected
4. Frontend fetches via `/api/sessions` and displays in dashboard

## Critical Patterns

### JWT Authentication Flow
- **Login**: POST `/api/auth/login` → returns JWT token → stored in localStorage
- **Verification**: All protected routes check `Authorization: Bearer <token>` header
- **Token validation**: Backend middleware in `routes/auth.js` verifies JWT signature
- **Auto-logout**: Frontend checks token age (6h limit) in `App.jsx` useEffect
- **Setup**: First-time admin password via POST `/api/auth/setup`

### Session Data Structure
See `models/Session.js`:
- `session_id`: Unique identifier (format: `YYYYMMDD_HHMMSS_xxxxx`)
- `device_info`: Hostname, username, IP captured on first POST
- `data` object: Nested subdocuments for chrome_history, wifi_passwords, etc.
- `items_collected`: Array tracking which data types received
- `status`: "partial" or "complete" (auto-set when ≥5 types collected)

### API Endpoint Patterns
All routes under `/api`:
- `/api/data` - POST (no auth required for collectors)
- `/api/sessions` - GET (auth required)
- `/api/sessions/:session_id` - GET (auth required)
- `/api/auth/login` - POST
- `/api/auth/verify` - GET (token validation)
- `/api/auth/setup` - POST (first-time only)

### Environment Variables
**Backend** (`.env`):
```
MONGODB_URI=mongodb+srv://...
JWT_SECRET=<secure-random-string>
FRONTEND_URL=https://your-frontend.vercel.app
PORT=8080
```

**Frontend** (`.env`):
```
VITE_API_URL=http://localhost:8080/api  # or production URL
```

## Development Workflows

### Local Development
```bash
# Backend
cd backend
npm install
npm start  # or npm run dev with nodemon

# Frontend (separate terminal)
cd Frontend
npm install
npm run dev  # Opens http://localhost:5173
```

### First-Time Setup
```bash
# After backend is running
curl -X POST http://localhost:8080/api/auth/setup \
  -H "Content-Type: application/json" \
  -d '{"password": "your_password"}'
```

### Deployment (Vercel)
- Both backend and frontend deploy as separate Vercel projects
- Backend uses `vercel.json` with serverless function configuration
- Frontend uses `vercel.json` with SPA routing rewrites
- See [DEPLOYMENT.md](DEPLOYMENT.md) for complete steps

### CORS Configuration
Backend `server.js` whitelists origins:
```javascript
const allowedOrigins = [
  'http://localhost:5173',
  'http://localhost:3000',
  process.env.FRONTEND_URL
].filter(Boolean);
```
Add production frontend URL to `FRONTEND_URL` env var after deployment.

## Code Conventions

### Backend
- Use async/await (no .then() chains)
- All route handlers have try/catch with error logging
- MongoDB queries use `.select('-data')` to exclude large fields from lists
- Session updates use `await session.save()` pattern (not `findByIdAndUpdate`)

### Frontend
- Environment variables accessed via `import.meta.env.VITE_*`
- API URL pattern: `const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api'`
- Protected routes wrapped in authentication checks in `App.jsx`
- JWT token stored as `authToken` in localStorage (never plain passwords)
- All axios requests to protected endpoints include `Authorization: Bearer ${token}` header

### Component Structure
- Pages in `Frontend/src/pages/` (Login, Dashboard, SessionDetail)
- Shared components in `Frontend/src/components/`
- Lucide-react icons imported individually: `import { Icon } from 'lucide-react'`
- Date formatting via date-fns: `formatDistanceToNow(new Date(timestamp))`

## Key Files to Reference

- [backend/server.js](backend/server.js) - Express app setup, CORS, MongoDB connection
- [backend/routes/data.js](backend/routes/data.js) - Data ingestion logic, session completion rules
- [backend/routes/auth.js](backend/routes/auth.js) - JWT generation and verification
- [backend/models/Session.js](backend/models/Session.js) - Session schema with data types
- [Frontend/src/App.jsx](Frontend/src/App.jsx) - Auth state management, token verification
- [Frontend/src/pages/Dashboard.jsx](Frontend/src/pages/Dashboard.jsx) - Session list, search/filter
- [SECURITY_UPDATE.md](SECURITY_UPDATE.md) - JWT authentication implementation details
- [DEPLOYMENT.md](DEPLOYMENT.md) - Vercel deployment guide with environment variables

## Common Tasks

### Adding New Data Type
1. Update `dataTypeMap` in `backend/routes/data.js`
2. Add field to `Session.data` schema in `models/Session.js`
3. Update `expectedTypes` array for completion logic
4. Add UI rendering in `Frontend/src/pages/SessionDetail.jsx`

### Modifying Token Expiration
Change `JWT_EXPIRES_IN` constant in `backend/routes/auth.js` and update `sixHours` calculation in `Frontend/src/App.jsx` to match.

### Adding Protected Route
1. Create JWT verification middleware (see `routes/auth.js` verifyToken)
2. Apply middleware to route: `router.get('/endpoint', verifyToken, handler)`
3. Frontend must send `Authorization: Bearer ${token}` header

### Debugging Auth Issues
- Check browser DevTools → Application → Local Storage for `authToken`
- Verify token with: `curl -H "Authorization: Bearer <token>" http://localhost:8080/api/auth/verify`
- Check backend logs for JWT verification errors
- Ensure `JWT_SECRET` matches between login and verification
