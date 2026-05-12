const { max } = require("lodash");
const mongoose = require("mongoose");

const userSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: true,
  },
  lastName: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },

  phoneNumber: {
    type: String,
    maxlength: 11,
  },

  password: {
    type: String,
    required: true,
  },
  profileImage: {
    type: String,
  },
  userRole: {
    type: String,
    enum: ["user", "owner", "admin"],
    default: "user",
  },
  timestamp: {
    type: Date,
    default: Date.now,
  },
});

const User = mongoose.model("User", userSchema);
module.exports = User;