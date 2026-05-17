const { body, validationResult } = require("express-validator");

/**
 * Runs accumulated express-validator checks and short-circuits
 * the request with a 400 if any fail.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      data: null,
      message: errors
        .array()
        .map((e) => e.msg)
        .join(", "),
    });
  }
  next();
};

// ─── Rule sets ────────────────────────────────────────────────────────────────

const registerRules = [
  body("firstName")
    .trim()
    .notEmpty()
    .withMessage("First name is required")
    .isLength({ max: 50 })
    .withMessage("First name must be at most 50 characters"),

  body("lastName")
    .trim()
    .notEmpty()
    .withMessage("Last name is required")
    .isLength({ max: 50 })
    .withMessage("Last name must be at most 50 characters"),

  body("email")
    .trim()
    .notEmpty()
    .withMessage("Email is required")
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("password")
    .notEmpty()
    .withMessage("Password is required")
    .isLength({ min: 8 })
    .withMessage("Password must be at least 8 characters")
    .matches(/[A-Z]/)
    .withMessage("Password must contain at least one uppercase letter")
    .matches(/[0-9]/)
    .withMessage("Password must contain at least one number"),

  body("phoneNumber")
    .optional()
    .isLength({ min: 11, max: 11 })
    .withMessage("Phone number must be exactly 11 digits")
    .isNumeric()
    .withMessage("Phone number must contain only digits"),

  body("userRole")
    .optional()
    .isIn(["user", "owner"])
    .withMessage("Role must be either 'user' or 'owner'"),
];

const loginRules = [
  body("email")
    .trim()
    .notEmpty()
    .withMessage("Email is required")
    .isEmail()
    .withMessage("Please provide a valid email address")
    .normalizeEmail(),

  body("password").notEmpty().withMessage("Password is required"),
];

const changePasswordRules = [
  body("currentPassword")
    .notEmpty()
    .withMessage("Current password is required"),

  body("newPassword")
    .notEmpty()
    .withMessage("New password is required")
    .isLength({ min: 8 })
    .withMessage("New password must be at least 8 characters")
    .matches(/[A-Z]/)
    .withMessage("New password must contain at least one uppercase letter")
    .matches(/[0-9]/)
    .withMessage("New password must contain at least one number"),
];

module.exports = {
  validate,
  registerRules,
  loginRules,
  changePasswordRules,
};