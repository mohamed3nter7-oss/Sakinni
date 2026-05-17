// routes/userRoutes.js

const express = require("express");
const userRouter = express.Router(); // ✅ no app import

const {
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
} = require("../controllers/userController");

const { protect, restrictTo } = require("../middlewares/authMiddleware");

// ✅ All user management routes are protected
// ✅ Paths are relative — prefix /api/users is defined in app.js

userRouter.get("/", protect, restrictTo("admin"), getAllUsers);
userRouter.get("/:id", protect, getUserById);
userRouter.patch("/:id", protect, updateUser);
userRouter.delete("/:id", protect, restrictTo("admin"), deleteUser);

module.exports = userRouter;