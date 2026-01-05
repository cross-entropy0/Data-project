import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import axios from 'axios';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import SessionDetail from './pages/SessionDetail';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is authenticated and session is still valid (< 6 hours)
    const verifyAuth = async () => {
      const loginTime = localStorage.getItem('loginTime');
      const token = localStorage.getItem('authToken');
      
      if (loginTime && token) {
        const elapsed = Date.now() - parseInt(loginTime);
        const sixHours = 6 * 60 * 60 * 1000; // 6 hours in milliseconds
        
        if (elapsed < sixHours) {
          // Verify token with backend
          try {
            const response = await axios.get(`${API_URL}/auth/verify`, {
              headers: { Authorization: `Bearer ${token}` }
            });
            
            if (response.data.success && response.data.valid) {
              setIsAuthenticated(true);
            } else {
              // Invalid token
              localStorage.removeItem('loginTime');
              localStorage.removeItem('authToken');
            }
          } catch (error) {
            // Token verification failed
            console.error('Token verification failed:', error);
            localStorage.removeItem('loginTime');
            localStorage.removeItem('authToken');
          }
        } else {
          // Auto-lock after 6 hours
          localStorage.removeItem('loginTime');
          localStorage.removeItem('authToken');
        }
      }
      
      setLoading(false);
    };
    
    verifyAuth();
  }, []);

  const handleLogin = () => {
    setIsAuthenticated(true);
    localStorage.setItem('loginTime', Date.now().toString());
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    localStorage.removeItem('loginTime');
    localStorage.removeItem('authToken');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <Router>
      <Routes>
        <Route
          path="/login"
          element={
            isAuthenticated ? (
              <Navigate to="/dashboard" replace />
            ) : (
              <Login onLogin={handleLogin} />
            )
          }
        />
        <Route
          path="/dashboard"
          element={
            isAuthenticated ? (
              <Dashboard onLogout={handleLogout} />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
        <Route
          path="/session/:sessionId"
          element={
            isAuthenticated ? (
              <SessionDetail onLogout={handleLogout} />
            ) : (
              <Navigate to="/login" replace />
            )
          }
        />
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
