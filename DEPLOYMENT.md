# Deployment Guide - Vercel

## Security Improvements Implemented

✅ **JWT-based Authentication** - No more password storage in localStorage
✅ **Token Verification** - Backend validates JWT tokens on every request
✅ **6-hour Token Expiration** - Automatic session timeout
✅ **Secure CORS** - Configured for production origins only
✅ **Environment Variables** - Sensitive data stored securely

---

## Backend Deployment (Vercel)

### 1. Push your code to GitHub
```bash
cd /Users/akash/All\ code/Shell/Testing/data_project/backend
git init
git add .
git commit -m "Initial backend with JWT authentication"
# Create a GitHub repo and push
git remote add origin https://github.com/yourusername/your-backend-repo.git
git push -u origin main
```

### 2. Deploy to Vercel
1. Go to [vercel.com](https://vercel.com) and sign in
2. Click "Add New Project"
3. Import your backend GitHub repository
4. Configure Environment Variables:
   - `MONGODB_URI`: `mongodb+srv://monkeiydluffy752:hdx2lkDWkNhNOggC@cluster0.jtvkt.mongodb.net/stealed_data`
   - `JWT_SECRET`: Generate a secure random string (use: `openssl rand -base64 32`)
   - `FRONTEND_URL`: (Add after deploying frontend)
   - `PORT`: `8080`

5. Click "Deploy"
6. Copy your backend URL (e.g., `https://your-backend.vercel.app`)

---

## Frontend Deployment (Vercel)

### 1. Update Frontend Environment Variable
```bash
cd /Users/akash/All\ code/Shell/Testing/data_project/Frontend
```

Edit `.env`:
```
VITE_API_URL=https://your-backend.vercel.app/api
```

### 2. Push to GitHub
```bash
git init
git add .
git commit -m "Initial frontend with JWT authentication"
# Create a GitHub repo and push
git remote add origin https://github.com/yourusername/your-frontend-repo.git
git push -u origin main
```

### 3. Deploy to Vercel
1. Go to [vercel.com](https://vercel.com)
2. Click "Add New Project"
3. Import your frontend GitHub repository
4. Configure Build Settings:
   - Framework Preset: `Vite`
   - Build Command: `npm run build`
   - Output Directory: `dist`
5. Add Environment Variable:
   - `VITE_API_URL`: `https://your-backend.vercel.app/api`
6. Click "Deploy"
7. Copy your frontend URL (e.g., `https://your-frontend.vercel.app`)

### 4. Update Backend CORS
Go back to Vercel backend project → Settings → Environment Variables:
- Add/Update `FRONTEND_URL`: `https://your-frontend.vercel.app`
- Redeploy backend

---

## Testing the Deployment

### 1. Setup Admin Password
```bash
curl -X POST https://your-backend.vercel.app/api/auth/setup \
  -H "Content-Type: application/json" \
  -d '{"password": "your_secure_password"}'
```

### 2. Test Login
Visit `https://your-frontend.vercel.app/login` and enter your password

### 3. Verify JWT Token
Open browser DevTools → Application → Local Storage
- Should see `authToken` (JWT) instead of `authPassword`
- Token format: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

---

## Security Checklist

- [ ] Changed `JWT_SECRET` to a secure random string
- [ ] Never commit `.env` files to Git
- [ ] MongoDB Atlas IP whitelist configured (allow all: `0.0.0.0/0` for Vercel)
- [ ] Frontend `VITE_API_URL` points to production backend
- [ ] Backend `FRONTEND_URL` matches deployed frontend
- [ ] Test login/logout flow on production
- [ ] Test 6-hour auto-lock feature
- [ ] Verify JWT token in localStorage (not password)

---

## Generate Secure JWT Secret

```bash
# On macOS/Linux
openssl rand -base64 32

# On Windows (PowerShell)
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

Use the generated string as your `JWT_SECRET` in Vercel environment variables.

---

## Local Development

### Backend
```bash
cd backend
npm install
npm start
```

### Frontend
```bash
cd Frontend
npm install
npm run dev
```

Frontend will connect to backend via `VITE_API_URL` from `.env` file.

---

## Troubleshooting

### CORS Errors
- Ensure `FRONTEND_URL` in backend matches your deployed frontend URL
- Check Vercel logs: Deployments → View Function Logs

### Authentication Failing
- Verify JWT_SECRET is set in both local and production
- Check token in localStorage (DevTools → Application)
- Test token verification endpoint: `GET /api/auth/verify`

### MongoDB Connection Issues
- MongoDB Atlas → Network Access → Add `0.0.0.0/0` for Vercel
- Verify `MONGODB_URI` in Vercel environment variables
