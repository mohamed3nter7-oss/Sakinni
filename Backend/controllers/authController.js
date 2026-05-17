const User = require("../models/userModel");
const {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
} = require("../utils/jwtUtils");

// ─── Constants ────────────────────────────────────────────────────────────────
const MAX_LOGIN_ATTEMPTS = 5;
const LOCK_DURATION_MS = 15 * 60 * 1000; // 15 minutes

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Strip sensitive fields and return a safe user object.
 */
const sanitizeUser = (user) => ({
  _id: user._id,
  firstName: user.firstName,
  lastName: user.lastName,
  email: user.email,
  phoneNumber: user.phoneNumber,
  profileImage: user.profileImage,
  userRole: user.userRole,
  createdAt: user.createdAt,
});

/**
 * Set the refresh token as an HttpOnly cookie.
 */
const setRefreshCookie = (res, token) => {
  res.cookie("refreshToken", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days in ms
  });
};

// ─── Controllers ──────────────────────────────────────────────────────────────

/**
 * @desc    Register a new user
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = async (req, res) => {
  try {
    const { firstName, lastName, email, password, phoneNumber, userRole } =
      req.body;

    // Check for duplicate email
    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({
        success: false,
        data: null,
        message: "An account with this email already exists",
      });
    }

    const user = await User.create({
      firstName,
      lastName,
      email,
      password,
      phoneNumber,
      userRole: "user",
    });

    const accessToken = generateAccessToken({
      id: user._id,
      userRole: user.userRole,
    });
    const refreshToken = generateRefreshToken({ id: user._id });

    // Persist hashed refresh token for rotation / revocation checks
    user.refreshToken = refreshToken;
    await user.save({ validateBeforeSave: false });

    setRefreshCookie(res, refreshToken);

    return res.status(201).json({
      success: true,
      data: { user: sanitizeUser(user), accessToken },
      message: "Account created successfully",
    });
  } catch (err) {
    // Mongoose validation errors
    if (err.name === "ValidationError") {
      const messages = Object.values(err.errors).map((e) => e.message);
      return res.status(400).json({
        success: false,
        data: null,
        message: messages.join(", "),
      });
    }
    console.error("[register]", err);
    return res.status(500).json({
      success: false,
      data: null,
      message: "Internal server error",
    });
  }
};

/**
 * @desc    Login with email & password
 * @route   POST /api/auth/login
 * @access  Public
 */
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        data: null,
        message: "Email and password are required",
      });
    }

    // Explicitly select hidden fields needed for auth checks
    const user = await User.findOne({ email: email.toLowerCase() }).select(
      "+password +loginAttempts +lockUntil +refreshToken",
    );

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        data: null,
        message: "Invalid credentials",
      });
    }

    // ── Brute-force guard ──────────────────────────────────────────────────
    if (user.isLocked()) {
      const minutesLeft = Math.ceil((user.lockUntil - Date.now()) / 60000);
      return res.status(423).json({
        success: false,
        data: null,
        message: `Account locked. Try again in ${minutesLeft} minute(s)`,
      });
    }

    const isMatch = await user.comparePassword(password);

    if (!isMatch) {
      // Increment failed attempts
      user.loginAttempts += 1;
      if (user.loginAttempts >= MAX_LOGIN_ATTEMPTS) {
        user.lockUntil = new Date(Date.now() + LOCK_DURATION_MS);
        user.loginAttempts = 0; // reset counter after locking
      }
      await user.save({ validateBeforeSave: false });

      return res.status(401).json({
        success: false,
        data: null,
        message: "Invalid credentials",
      });
    }

    // Successful login — reset brute-force counters
    user.loginAttempts = 0;
    user.lockUntil = undefined;

    const accessToken = generateAccessToken({
      id: user._id,
      userRole: user.userRole,
    });
    const refreshToken = generateRefreshToken({ id: user._id });

    user.refreshToken = refreshToken;
    await user.save({ validateBeforeSave: false });

    setRefreshCookie(res, refreshToken);

    return res.status(200).json({
      success: true,
      data: { user: sanitizeUser(user), accessToken },
      message: "Logged in successfully",
    });
  } catch (err) {
    console.error("[login]", err);
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};

/**
 * @desc    Refresh access token using the HttpOnly cookie
 * @route   POST /api/auth/refresh-token
 * @access  Public (requires valid refresh cookie)
 */
const refreshToken = async (req, res) => {
  try {
    const token = req.cookies?.refreshToken;

    if (!token) {
      return res.status(401).json({
        success: false,
        data: null,
        message: "No refresh token provided",
      });
    }

    // Verify signature & expiry
    let decoded;
    try {
      decoded = verifyRefreshToken(token);
    } catch {
      return res.status(403).json({
        success: false,
        data: null,
        message: "Invalid or expired refresh token",
      });
    }

    // Validate token matches what is stored (rotation check)
    const user = await User.findById(decoded.id).select("+refreshToken");

    if (!user || user.refreshToken !== token) {
      // Possible token reuse — clear stored token as a precaution
      if (user) {
        user.refreshToken = undefined;
        await user.save({ validateBeforeSave: false });
      }
      return res.status(403).json({
        success: false,
        data: null,
        message: "Refresh token reuse detected. Please log in again",
      });
    }

    // Issue a new token pair (rotation)
    const newAccessToken = generateAccessToken({
      id: user._id,
      userRole: user.userRole,
    });
    const newRefreshToken = generateRefreshToken({ id: user._id });

    user.refreshToken = newRefreshToken;
    await user.save({ validateBeforeSave: false });

    setRefreshCookie(res, newRefreshToken);

    return res.status(200).json({
      success: true,
      data: { accessToken: newAccessToken },
      message: "Token refreshed",
    });
  } catch (err) {
    console.error("[refreshToken]", err);
    return res.status(500).json({
      success: false,
      data: null,
      message: "Internal server error",
    });
  }
};

/**
 * @desc    Logout — clear cookie and invalidate stored refresh token
 * @route   POST /api/auth/logout
 * @access  Private
 */
const logout = async (req, res) => {
  try {
    const token = req.cookies?.refreshToken;

    if (token) {
      // Invalidate the stored refresh token
      await User.findOneAndUpdate(
        { refreshToken: token },
        { $unset: { refreshToken: "" } },
      );
    }

    res.clearCookie("refreshToken", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
    });

    return res.status(200).json({
      success: true,
      data: null,
      message: "Logged out successfully",
    });
  } catch (err) {
    console.error("[logout]", err);
    return res.status(500).json({
      success: false,
      data: null,
      message: "Internal server error",
    });
  }
};

/**
 * @desc    Get current authenticated user's profile
 * @route   GET /api/auth/me
 * @access  Private
 */
const getMe = async (req, res) => {
  try {
    // req.user is populated by the protect middleware
    const user = await User.findById(req.user.id);

    if (!user || !user.isActive) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "User not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: { user: sanitizeUser(user) },
      message: "User fetched successfully",
    });
  } catch (err) {
    console.error("[getMe]", err);
    return res.status(500).json({
      success: false,
      data: null,
      message: "Internal server error",
    });
  }
};

/**
 * @desc    Change password for authenticated user
 * @route   PATCH /api/auth/change-password
 * @access  Private
 */
const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        data: null,
        message: "Current and new passwords are required",
      });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        data: null,
        message: "New password must be at least 8 characters",
      });
    }

    const user = await User.findById(req.user.id).select("+password");

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        data: null,
        message: "Current password is incorrect",
      });
    }

    user.password = newPassword; // pre-save hook will hash it
    await user.save();

    return res.status(200).json({
      success: true,
      data: null,
      message: "Password changed successfully. Please log in again",
    });
  } catch (err) {
    console.error("[changePassword]", err);
    return res.status(500).json({
      success: false,
      data: null,
      message: "Internal server error",
    });
  }
};

module.exports = {
  register,
  login,
  refreshToken,
  logout,
  getMe,
  changePassword,
};
