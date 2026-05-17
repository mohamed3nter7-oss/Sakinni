const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema(
  {
    firstName: {
      type: String,
      required: [true, "First name is required"],
      trim: true,
    },
    lastName: {
      type: String,
      required: [true, "Last name is required"],
      trim: true,
    },
    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, "Please provide a valid email address"],
    },
    phoneNumber: {
      type: String,
      minlength: [11, "Phone number must be exactly 11 digits"],
      maxlength: [11, "Phone number must be exactly 11 digits"],
      match: [/^\d{11}$/, "Phone number must contain only digits"],
    },
    password: {
      type: String,
      required: [true, "Password is required"],
      minlength: [8, "Password must be at least 8 characters"],
      select: false, // Never return password in queries by default
    },
    profileImage: {
      type: String,
      default: null,
    },
    userRole: {
      type: String,
      enum: {
        values: ["user", "owner", "admin"],
        message: "Role must be one of: user, owner, admin",
      },
      default: "user",
    },
    // Refresh token stored for stateless JWT rotation
    refreshToken: {
      type: String,
      select: false,
    },
    // Track failed login attempts for basic brute-force protection
    loginAttempts: {
      type: Number,
      default: 0,
      select: false,
    },
    lockUntil: {
      type: Date,
      select: false,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    passwordChangedAt: {
      type: Date,
      select: false,
    },
  },
  {
    timestamps: true, // adds createdAt and updatedAt automatically
  }
);

// ─── Indexes ─────────────────────────────────────────────────────────────────
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ userRole: 1 });

// ─── Virtual: full name ───────────────────────────────────────────────────────
userSchema.virtual("fullName").get(function () {
  return `${this.firstName} ${this.lastName}`;
});

// ─── Pre-save: hash password ──────────────────────────────────────────────────
userSchema.pre("save", async function (next) {
  // Only hash if the password field was modified (or is new)
  if (!this.isModified("password")) return next();

  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);

  // Record when the password was last changed (skip on first save)
  if (!this.isNew) {
    this.passwordChangedAt = Date.now() - 1000; // 1s buffer for JWT iat
  }

  next();
});

// ─── Instance method: compare passwords ──────────────────────────────────────
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// ─── Instance method: check if account is locked ─────────────────────────────
userSchema.methods.isLocked = function () {
  return this.lockUntil && this.lockUntil > Date.now();
};

const User = mongoose.model("User", userSchema);
module.exports = User;