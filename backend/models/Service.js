const mongoose = require('mongoose');

const ServiceSchema = new mongoose.Schema({
  title: String,
  providerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Service', ServiceSchema);
