const mongoose = require('mongoose');

const DroneSchema = new mongoose.Schema({
  model: String,
  ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  available: Boolean,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Drone', DroneSchema);
