const mongoose = require("mongoose");
const Chat = require("../models/chatModel");

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Builds a consistent response object.
 */
const respond = (res, statusCode, success, message, data = null) =>
  res.status(statusCode).json({ success, message, data });

/**
 * Returns the "other" participant ID from a chat's participants array.
 */
const getOtherParticipant = (participants, currentUserId) =>
  participants.find((id) => id.toString() !== currentUserId.toString());

// ─── GET ALL CHATS FOR CURRENT USER ──────────────────────────────────────────
/**
 * GET /api/chats
 * Returns all chats the logged-in user is part of, sorted by latest message.
 * Mirrors: Firestore stream on 'chats' where participants arrayContains currentUserId
 */
const getMyChats = async (req, res) => {
  try {
    const currentUserId = req.user.id;

    const chats = await Chat.find({ participants: currentUserId })
      .sort({ lastMessageTime: -1 })
      // Return everything EXCEPT the embedded messages array (for list view)
      .select("-messages")
      .lean();

    // Shape each chat: add unread count for current user + other participant info
    const shaped = chats.map((chat) => {
      const otherUserId = getOtherParticipant(chat.participants, currentUserId);
      const names = chat.participantNames || {};
      const unread = chat.unreadCount || {};

      return {
        chatId: chat._id,
        otherUserId,
        otherUserName: names[otherUserId?.toString()] ?? "User",
        lastMessage:
          chat.lastMessageType === "image" ? "📷 Photo" : chat.lastMessage,
        lastMessageType: chat.lastMessageType,
        lastMessageTime: chat.lastMessageTime,
        unreadCount: unread[currentUserId.toString()] ?? 0,
      };
    });

    return respond(res, 200, true, "Chats fetched successfully.", shaped);
  } catch (error) {
    console.error("getMyChats error:", error);
    return respond(res, 500, false, "Server error while fetching chats.");
  }
};

// ─── GET SINGLE CHAT WITH MESSAGES ───────────────────────────────────────────
/**
 * GET /api/chats/:chatId
 * Returns a single chat document WITH all messages.
 * Also marks all messages as read for the current user (resets unread count).
 */
const getChatById = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { chatId } = req.params;

    const chat = await Chat.findOne({
      _id: chatId,
      participants: currentUserId, // Security: user must be a participant
    });

    if (!chat) {
      return respond(res, 404, false, "Chat not found or access denied.");
    }

    // ── Mark as read: reset unread count for current user ──
    chat.unreadCount.set(currentUserId.toString(), 0);

    // Mark all messages as read by current user
    chat.messages.forEach((msg) => {
      if (!msg.readBy.includes(currentUserId)) {
        msg.readBy.push(currentUserId);
      }
    });

    await chat.save();

    return respond(res, 200, true, "Chat fetched successfully.", chat);
  } catch (error) {
    console.error("getChatById error:", error);
    return respond(res, 500, false, "Server error while fetching chat.");
  }
};

// ─── START OR RETRIEVE A CHAT ─────────────────────────────────────────────────
/**
 * POST /api/chats
 * Creates a new chat between current user and otherUserId,
 * OR returns the existing one if it already exists.
 * Mirrors: _initializeChat() in Flutter
 *
 * Body: { otherUserId, otherUserName, myName }
 */
const startOrGetChat = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { otherUserId, otherUserName, myName = "User" } = req.body;

    // Prevent chatting with yourself
    if (currentUserId.toString() === otherUserId.toString()) {
      return respond(res, 400, false, "You cannot start a chat with yourself.");
    }

    // Check if chat already exists between these two users
    let chat = await Chat.findOne({
      participants: { $all: [currentUserId, otherUserId] },
    }).select("-messages"); // Don't load messages for this response

    if (chat) {
      // Chat exists — update names in case they changed
      chat.participantNames.set(currentUserId.toString(), myName);
      chat.participantNames.set(otherUserId.toString(), otherUserName);
      await chat.save();

      return respond(res, 200, true, "Chat already exists.", {
        chatId: chat._id,
        isNew: false,
      });
    }

    // ── Create new chat ──
    chat = new Chat({
      participants: [currentUserId, otherUserId],
      participantNames: new Map([
        [currentUserId.toString(), myName],
        [otherUserId.toString(), otherUserName],
      ]),
      unreadCount: new Map([
        [currentUserId.toString(), 0],
        [otherUserId.toString(), 0],
      ]),
      lastMessage: "",
      lastMessageTime: new Date(),
    });

    await chat.save();

    return respond(res, 201, true, "Chat created successfully.", {
      chatId: chat._id,
      isNew: true,
    });
  } catch (error) {
    console.error("startOrGetChat error:", error);
    return respond(res, 500, false, "Server error while creating chat.");
  }
};

// ─── SEND A MESSAGE ───────────────────────────────────────────────────────────
/**
 * POST /api/chats/:chatId/messages
 * Appends a new message (text or image) to the chat.
 * Updates lastMessage snapshot and increments unread count for the OTHER user.
 * Mirrors: sendMessage() in Flutter
 *
 * Body: { type: 'text'|'image', text?, imageUrl? }
 */
const sendMessage = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { chatId } = req.params;
    const { type, text, imageUrl } = req.body;

    const chat = await Chat.findOne({
      _id: chatId,
      participants: currentUserId,
    });

    if (!chat) {
      return respond(res, 404, false, "Chat not found or access denied.");
    }

    // ── Build new message ──
    const newMessage = {
      senderId: currentUserId,
      type,
      text: type === "text" ? text.trim() : null,
      imageUrl: type === "image" ? imageUrl.trim() : null,
      readBy: [currentUserId], // Sender has already "read" their own message
    };

    chat.messages.push(newMessage);

    // ── Update chat-level snapshot ──
    chat.lastMessage = type === "image" ? "📷 Photo" : text.trim();
    chat.lastMessageType = type;
    chat.lastMessageTime = new Date();
    chat.lastMessageSenderId = currentUserId;

    // ── Increment unread count for the OTHER participant only ──
    const otherUserId = getOtherParticipant(chat.participants, currentUserId);
    if (otherUserId) {
      const currentUnread = chat.unreadCount.get(otherUserId.toString()) ?? 0;
      chat.unreadCount.set(otherUserId.toString(), currentUnread + 1);
    }

    await chat.save();

    // Return only the newly added message (last in array)
    const savedMessage = chat.messages[chat.messages.length - 1];

    return respond(res, 201, true, "Message sent.", savedMessage);
  } catch (error) {
    console.error("sendMessage error:", error);
    return respond(res, 500, false, "Server error while sending message.");
  }
};

// ─── DELETE A MESSAGE ─────────────────────────────────────────────────────────
/**
 * DELETE /api/chats/:chatId/messages/:messageId
 * Soft-deletes a message by replacing its content with a placeholder.
 * Only the sender can delete their own message.
 */
const deleteMessage = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { chatId, messageId } = req.params;

    const chat = await Chat.findOne({
      _id: chatId,
      participants: currentUserId,
    });

    if (!chat) {
      return respond(res, 404, false, "Chat not found or access denied.");
    }

    const message = chat.messages.id(messageId);

    if (!message) {
      return respond(res, 404, false, "Message not found.");
    }

    // Only sender can delete their message
    if (message.senderId.toString() !== currentUserId.toString()) {
      return respond(res, 403, false, "You can only delete your own messages.");
    }

    // Soft delete: replace content instead of hard removal
    message.text = "This message was deleted.";
    message.imageUrl = null;
    message.type = "text";

    await chat.save();

    return respond(res, 200, true, "Message deleted.", { messageId });
  } catch (error) {
    console.error("deleteMessage error:", error);
    return respond(res, 500, false, "Server error while deleting message.");
  }
};

// ─── DELETE (CLEAR) AN ENTIRE CHAT ───────────────────────────────────────────
/**
 * DELETE /api/chats/:chatId
 * Clears all messages from a chat. Chat document itself is kept.
 * Both participants can trigger this.
 */
const deleteChat = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { chatId } = req.params;

    const chat = await Chat.findOne({
      _id: chatId,
      participants: currentUserId,
    });

    if (!chat) {
      return respond(res, 404, false, "Chat not found or access denied.");
    }

    // Clear all messages and reset snapshot
    chat.messages = [];
    chat.lastMessage = "";
    chat.lastMessageTime = null;
    chat.lastMessageSenderId = null;
    chat.unreadCount = new Map();

    await chat.save();

    return respond(res, 200, true, "Chat cleared successfully.");
  } catch (error) {
    console.error("deleteChat error:", error);
    return respond(res, 500, false, "Server error while clearing chat.");
  }
};

// ─── MARK CHAT AS READ ────────────────────────────────────────────────────────
/**
 * PATCH /api/chats/:chatId/read
 * Resets unread count to 0 for the current user in this chat.
 * Call this when user opens a chat.
 */
const markAsRead = async (req, res) => {
  try {
    const currentUserId = req.user.id;
    const { chatId } = req.params;

    const chat = await Chat.findOne({
      _id: chatId,
      participants: currentUserId,
    });

    if (!chat) {
      return respond(res, 404, false, "Chat not found or access denied.");
    }

    chat.unreadCount.set(currentUserId.toString(), 0);
    await chat.save();

    return respond(res, 200, true, "Chat marked as read.");
  } catch (error) {
    console.error("markAsRead error:", error);
    return respond(res, 500, false, "Server error while marking as read.");
  }
};

module.exports = {
  getMyChats,
  getChatById,
  startOrGetChat,
  sendMessage,
  deleteMessage,
  deleteChat,
  markAsRead,
};
