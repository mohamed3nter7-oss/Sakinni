const mongoose = require("mongoose");

const paymentSchema = new mongoose.Schema({

  userId: {
    type: String,
    required: true,
  },

  propertyId: {
    type: String,
    required: true,
  },

  bookingId: {
    type: String,
    required: true,
  },

  amount: {
    type: Number,
    required: true,
  },

  currency: {
    type: String,
    default: "EGP",
  },

  status: {
    type: String,
    enum: ["pending", "completed", "failed", "refunded"],
    default: "pending",
  },

  paymentMethod: {
    type: String,
    enum: ["card", "paypal", "cash"],
    default: "card",
  },

  paymentDetails: {
    type: Object,
    default: {},
  },

  processedAt: {
    type: Date,
    default: null,
  },

}, {
  timestamps: true,
});


module.exports = mongoose.model("Payment", paymentSchema);