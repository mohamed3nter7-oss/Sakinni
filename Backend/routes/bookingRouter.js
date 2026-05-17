const express = require('express');
const router = express.Router();

const {
  getBookings,
  getMyBookings,
  getPropertyBookings,
  getBookingById,
  createBooking,
  cancelBooking,
  deleteBooking,
} = require('../Controllers/bookingController');

const { protect, restrictTo } = require('../middlewares/authMiddleware');

// ✅ All routes protected with auth
router.get("/", protect, restrictTo("admin"), getBookings);
router.get("/my-bookings", protect, getMyBookings);
router.get("/property-bookings", protect, restrictTo("owner", "admin"), getPropertyBookings);
router.get("/:id", protect, getBookingById);
router.post("/", protect, restrictTo("user"), createBooking);
router.patch("/:id/cancel", protect, cancelBooking);
router.delete("/:id", protect, restrictTo("admin"), deleteBooking);

module.exports = router;