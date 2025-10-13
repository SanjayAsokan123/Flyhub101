const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: String,
  email: String,
  role: { type: String, default: 'user' }, // could be 'admin'
  createdAt: { type: Date, default: Date.now }
});

//module.exports = mongoose.model('User', UserSchema);
module.exports=mongoose.model('User,'UserSchema);