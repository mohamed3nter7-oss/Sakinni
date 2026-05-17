require("dotenv").config();

const express = require("express");
const mongoose = require("mongoose");
const cookieParser = require("cookie-parser");
const cors = require("cors");
// ─── Route imports ────────────────────────────────────────────────────────────
const authRoutes = require("./routes/authRoutes");
const userRoutes = require("./routes/userRoutes");
const chatRoutes = require("./routes/chatRouter");
const bookingRouter = require("./routes/bookingRouter");
const paymentRouter = require("./routes/paymentRouter");
const propertyRouter = require("./routes/propertyRouter");
const app = express();

// ─── Global Middleware ────────────────────────────────────────────────────────
app.use(
  cors({
    origin: function (origin, callback) {
      // Allow requests with no origin (mobile apps, Postman, etc.)
      if (!origin) return callback(null, true);
      // Allow any localhost port (Flutter web dev uses random ports)
      if (/^http:\/\/localhost(:\d+)?$/.test(origin) || /^http:\/\/127\.0\.0\.1(:\d+)?$/.test(origin)) {
        return callback(null, true);
      }
      callback(new Error('Not allowed by CORS'));
    },
    credentials: true, // Required to allow cookies cross-origin
  })
);
app.use(express.json({ limit: "10kb" })); // Reject oversized JSON bodies
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser()); // Parses req.cookies for refresh token

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/chats", chatRoutes);
app.use("/api/bookings", bookingRouter);
app.use("/api/payments", paymentRouter);
app.use("/api/properties", propertyRouter);

// ─── 404 Handler ─────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    data: null,
    message: `Route ${req.method} ${req.originalUrl} not found`,
  });
});

// ─── Global Error Handler ─────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error("[Unhandled Error]", err);
  res.status(err.status || 500).json({
    success: false,
    data: null,
    message: err.message || "Internal server error",
  });
});


module.exports = app; // export for testing