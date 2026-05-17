const { verifyAccessToken } = require("../utils/jwtUtils");
const User = require("../models/userModel");

/**
 * @middleware protect
 * Verifies the JWT access token sent in the Authorization header.
 * Attaches the decoded user payload to req.user.
 *
 * Expected header: Authorization: Bearer <accessToken>
 */
const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        data: null,
        message: "Access denied. No token provided",
      });
    }

    const token = authHeader.split(" ")[1];

    // Throws if expired or tampered
    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (err) {
      const message =
        err.name === "TokenExpiredError"
          ? "Access token has expired"
          : "Invalid access token";
      return res.status(401).json({ success: false, data: null, message });
    }

    // Confirm user still exists and is active
    const user = await User.findById(decoded.id).select("+passwordChangedAt");

    if (!user || !user.isActive) {
      return res.status(401).json({
        success: false,
        data: null,
        message: "User belonging to this token no longer exists",
      });
    }

    // Invalidate tokens issued before a password change
    if (user.passwordChangedAt) {
      const changedAt = Math.floor(user.passwordChangedAt.getTime() / 1000);
      if (decoded.iat < changedAt) {
        return res.status(401).json({
          success: false,
          data: null,
          message: "Password was recently changed. Please log in again",
        });
      }
    }

    // Attach minimal user info to request
    req.user = { id: decoded.id, userRole: decoded.userRole };
    next();
  } catch (err) {
    console.error("[protect middleware]", err);
    return res.status(500).json({
      success: false,
      data: null,
      message: "Internal server error",
    });
  }
};

/**
 * @middleware restrictTo
 * Role-based access control — call after protect.
 *
 * Usage: restrictTo("admin", "owner")
 */
const restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.userRole)) {
      return res.status(403).json({
        success: false,
        data: null,
        message: "You do not have permission to perform this action",
      });
    }
    next();
  };
};

module.exports = { protect, restrictTo };
