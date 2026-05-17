// controllers/userController.js

const User = require("../models/userModel"); 

// ─── Get All Users (Admin only) ───────────────────────────────────────────────
const getAllUsers = async (req, res) => {
  try {
    const users = await User.find({ isActive: true }); 
    return res.status(200).json({
      success: true,
      data: users,
      message: "Users fetched successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

// ─── Get User By ID ───────────────────────────────────────────────────────────
const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user || !user.isActive) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "User not found",
      });
    }
    return res.status(200).json({
      success: true,
      data: user,
      message: "User fetched successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

// ─── Update User ──────────────────────────────────────────────────────────────
const updateUser = async (req, res) => {
  try {
    // ✅ Blacklist fields that must never be updated via this endpoint
    const { password, userRole, refreshToken, loginAttempts, ...safeFields } =
      req.body;

    const user = await User.findByIdAndUpdate(
      req.params.id,
      safeFields,
      { new: true, runValidators: true } // ✅ run schema validators on update
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "User not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: user,
      message: "User updated successfully",
    });
  } catch (error) {
    if (error.name === "ValidationError") {
      const messages = Object.values(error.errors).map((e) => e.message);
      return res.status(400).json({
        success: false,
        data: null,
        message: messages.join(", "),
      });
    }
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

// ─── Soft Delete User ─────────────────────────────────────────────────────────
const deleteUser = async (req, res) => {
  try {
    // ✅ Soft delete — sets isActive to false instead of removing the document
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive: false },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "User not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: null,
      message: "User deleted successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  updateUser,
  deleteUser,
};