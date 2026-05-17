const express = require("express");
const router = express.Router();

const {
  getPayments,
  getMyPayments,
  getPaymentById,
  createPayment,
  updatePayment,
  deletePayment,
} = require("../Controllers/paymentController");

const { protect, restrictTo } = require("../middlewares/authMiddleware");

// ✅ All routes protected
router.get("/", protect, restrictTo("admin"), getPayments);
router.get("/my-payments", protect, getMyPayments);
router.get("/:id", protect, getPaymentById);
router.post("/", protect, createPayment);
router.patch("/:id/status", protect, restrictTo("admin"), updatePayment);
router.delete("/:id", protect, restrictTo("admin"), deletePayment);

module.exports = router;