const express = require("express");
const router = express.Router();

const {
  register,
  login,
  refreshToken,
  logout,
  getMe,
  changePassword,
} = require("../controllers/authController");

const { protect } = require("../middlewares/authMiddleware");

const {
  validate,
  registerRules,
  loginRules,
  changePasswordRules,
} = require("../middlewares/authValidation");

// ─── Public routes ────────────────────────────────────────────────────────────

/**
 * POST /api/auth/register
 * Create a new user account
 */
router.post("/register", registerRules, validate, register);

/**
 * POST /api/auth/login
 * Authenticate and receive tokens
 */
router.post("/login", loginRules, validate, login);

/**
 * POST /api/auth/refresh-token
 * Exchange a valid refresh token (cookie) for a new access token
 */
router.post("/refresh-token", refreshToken);

/**
 * POST /api/auth/logout
 * Invalidate the current session / refresh token
 */
router.post("/logout", logout);

// ─── Protected routes (require valid access token) ───────────────────────────

/**
 * GET /api/auth/me
 * Retrieve the currently authenticated user's profile
 */
router.get("/me", protect, getMe);

/**
 * PATCH /api/auth/change-password
 * Update password for the authenticated user
 */
router.patch(
  "/change-password",
  protect,
  changePasswordRules,
  validate,
  changePassword
);

module.exports = router;