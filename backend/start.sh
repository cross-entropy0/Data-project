#!/bin/bash
# Quick Start Script for Backend Server

echo ""
echo "🚀 Starting Data Collection Backend..."
echo "========================================"
echo ""

cd "$(dirname "$0")"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create .env with your MongoDB URI"
    exit 1
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Kill existing server if running
if pgrep -f "node server.js" > /dev/null; then
    echo "🔄 Stopping existing server..."
    pkill -f "node server.js"
    sleep 1
fi

# Start server
echo "✨ Starting server on port 8080..."
echo ""
node server.js

# If server exits, show log
if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Server failed to start!"
    echo "Check error messages above"
    exit 1
fi
