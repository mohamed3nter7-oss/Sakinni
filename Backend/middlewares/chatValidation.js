/**
 * Validation Middleware for Chat Routes
 * Uses manual validation (no extra library needed).
 * Swap with express-validator or Joi if preferred.
 */

const mongoose = require("mongoose");

// ─── Helper ───────────────────────────────────────────────────────────────────
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

// ─── Validate: Start or Get Chat ──────────────────────────────────────────────
const validateStartChat = (req, res, next) => {
  const { otherUserId, otherUserName } = req.body;

  if (!otherUserId || !isValidObjectId(otherUserId)) {
    return res.status(400).json({
      success: false,
      data: null,
      message: "otherUserId is required and must be a valid MongoDB ObjectId.",
    });
  }

  if (!otherUserName || typeof otherUserName !== "string" || otherUserName.trim() === "") {
    return res.status(400).json({
      success: false,
      data: null,
      message: "otherUserName is required.",
    });
  }

  next();
};

// ─── Validate: Send Message ───────────────────────────────────────────────────
const validateSendMessage = (req, res, next) => {
  const { type, text, imageUrl } = req.body;

  // type must be 'text' or 'image'
  if (!type || !["text", "image"].includes(type)) {
    return res.status(400).json({
      success: false,
      data: null,
      message: "Message type must be 'text' or 'image'.",
    });
  }

  // If text message, text must not be empty
  if (type === "text" && (!text || text.trim() === "")) {
    return res.status(400).json({
      success: false,
      data: null,
      message: "text is required for text messages.",
    });
  }

  // If image message, imageUrl must be provided
  if (type === "image" && (!imageUrl || imageUrl.trim() === "")) {
    return res.status(400).json({
      success: false,
      data: null,
      message: "imageUrl is required for image messages.",
    });
  }

  next();
};

module.exports = { validateStartChat, validateSendMessage };
