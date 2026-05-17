const mongoose = require("mongoose");

// ─── Message Sub-Schema ───────────────────────────────────────────────────────
// Stored as embedded subdocuments inside each Chat document.
// Images are stored as URLs (e.g. after upload to S3/Cloudinary).
const MessageSchema = new mongoose.Schema(
  {
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "senderId is required"],
    },

    // Message type: text or image
    type: {
      type: String,
      enum: ["text", "image"],
      default: "text",
    },

    // Text content (required when type === 'text')
    text: {
      type: String,
      trim: true,
      default: null,
    },

    // Image URL (required when type === 'image')
    imageUrl: {
      type: String,
      default: null,
    },

    // Track which participants have read this message
    readBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
  },
  {
    timestamps: true, // createdAt = message sent time
  }
);

// ─── Chat Schema ──────────────────────────────────────────────────────────────
const ChatSchema = new mongoose.Schema(
  {
    // Array of exactly 2 user IDs (1-to-1 chat)
    participants: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
      },
    ],

    // Map: { userId -> displayName } for quick lookups without extra DB calls
    // Mirrors your Flutter participantNames map
    participantNames: {
      type: Map,
      of: String,
      default: {},
    },

    // Snapshot of the last message for the chat list preview
    lastMessage: {
      type: String,
      default: "",
    },

    // Type of last message for icon rendering on chat list (text/image)
    lastMessageType: {
      type: String,
      enum: ["text", "image"],
      default: "text",
    },

    lastMessageTime: {
      type: Date,
      default: null,
    },

    // Sender of the last message (to show "You: ..." on chat list)
    lastMessageSenderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    // Unread count per participant: { userId -> count }
    unreadCount: {
      type: Map,
      of: Number,
      default: {},
    },

    // All messages embedded in this chat
    messages: [MessageSchema],
  },
  {
    timestamps: true, // createdAt, updatedAt on the chat doc
  }
);

// ─── Indexes ──────────────────────────────────────────────────────────────────

// Fast lookup: "find all chats where user X is a participant"
ChatSchema.index({ participants: 1 });

// Fast sorting on chat list (most recent first)
ChatSchema.index({ lastMessageTime: -1 });

// Compound: participant + time (most common query pattern)
ChatSchema.index({ participants: 1, lastMessageTime: -1 });

// ─── Static Helper: Generate deterministic chat ID ────────────────────────────
// Sorts two user IDs so chat(A,B) === chat(B,A)
ChatSchema.statics.getChatId = function (userIdA, userIdB) {
  return [userIdA.toString(), userIdB.toString()].sort().join("_");
};

module.exports = mongoose.model("Chat", ChatSchema);
