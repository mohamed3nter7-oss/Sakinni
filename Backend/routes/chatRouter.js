const express = require("express");
const router = express.Router();

const {
  getMyChats,
  getChatById,
  startOrGetChat,
  sendMessage,
  deleteMessage,
  deleteChat,
  markAsRead,
} = require("../controllers/chatController");

const { protect, restrictTo } = require("../middlewares/authMiddleware");
const { validateStartChat, validateSendMessage } = require("../middlewares/chatValidation");
// ─── All routes below require a valid JWT ─────────────────────────────────────
router.use(protect);

// ─── Chat Routes ──────────────────────────────────────────────────────────────

/**
 * GET    /api/chats          → Get all chats for current user (list view)
 * POST   /api/chats          → Start or retrieve a chat with another user
 */
router
  .route("/")
  .get(getMyChats)
  .post(validateStartChat, startOrGetChat);

/**
 * GET    /api/chats/:chatId  → Get single chat WITH full message history
 * DELETE /api/chats/:chatId  → Clear all messages in a chat
 */
router
  .route("/:chatId")
  .get(getChatById)
  .delete(deleteChat);

/**
 * POST   /api/chats/:chatId/messages              → Send a new message (text or image)
 * DELETE /api/chats/:chatId/messages/:messageId   → Delete a specific message
 */
router
  .route("/:chatId/messages")
  .post(validateSendMessage, sendMessage);

router
  .route("/:chatId/messages/:messageId")
  .delete(deleteMessage);

/**
 * PATCH  /api/chats/:chatId/read  → Mark chat as read (reset unread count)
 */
router.patch("/:chatId/read", markAsRead);

module.exports = router;