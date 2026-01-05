const mongoose = require('mongoose');

const AdminSchema = new mongoose.Schema({
  password: {
    type: String,
    required: true
  },
  created_at: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Admin', AdminSchema);
