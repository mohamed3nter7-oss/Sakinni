const Booking = require('../models/bookingModel');
const { validationResult } = require('express-validator');

// GET all bookings (with optional filters)
const getBookings = async (req, res) => {
  try {
    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const bookings = await Booking.find(filter)
      .populate("user", "firstName lastName email phoneNumber") // ✅ populate
      .populate("property", "title location mainImage price")   // ✅ populate
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: bookings,
      message: "Bookings fetched successfully",
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};

// GET single booking
const getBookingById = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate("user", "firstName lastName email phoneNumber")
      .populate("property", "title location mainImage price owner");

    if (!booking) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Booking not found",
      });
    }

    // ✅ Only the booking user, property owner, or admin can view
    const isBookingUser = booking.user._id.toString() === req.user.id.toString();
    const isPropertyOwner = booking.property.owner.toString() === req.user.id.toString();
    const isAdmin = req.user.userRole === "admin";

    if (!isBookingUser && !isPropertyOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        data: null,
        message: "You are not allowed to view this booking",
      });
    }

    return res.status(200).json({
      success: true,
      data: booking,
      message: "Booking fetched successfully",
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};

// CREATE a booking (with validation)
const createBooking = async (req, res) => {
  try {
    const { property, startDate, endDate } = req.body;

    // ✅ Check property exists and is available
    const existingProperty = await Property.findById(property);
    if (!existingProperty || !existingProperty.isPublished) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Property not found",
      });
    }

    if (existingProperty.status !== "available") {
      return res.status(400).json({
        success: false,
        data: null,
        message: "Property is not available for booking",
      });
    }

    const booking = await Booking.create({
      property,
      user: req.user.id, // ✅ auto-set from token
      startDate,
      endDate,
    });

    // ✅ Update property status to booked
    await Property.findByIdAndUpdate(property, { status: "booked" });

    await booking.populate([
      { path: "user", select: "firstName lastName email" },
      { path: "property", select: "title location mainImage price" },
    ]);

    return res.status(201).json({
      success: true,
      data: booking,
      message: "Booking created successfully",
    });
  } catch (err) {
    if (err.name === "ValidationError") {
      const messages = Object.values(err.errors).map((e) => e.message);
      return res.status(400).json({
        success: false,
        data: null,
        message: messages.join(", "),
      });
    }
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};
// Get my Bookings
const getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ user: req.user.id })
      .populate("property", "title location mainImage price")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: bookings,
      message: "Your bookings fetched successfully",
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};

// CANCEL a booking
const cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Booking not found",
      });
    }

    // ✅ Only the user who made the booking can cancel it
    if (booking.user.toString() !== req.user.id.toString()) {
      return res.status(403).json({
        success: false,
        data: null,
        message: "You can only cancel your own bookings",
      });
    }

    if (booking.status === "cancelled") {
      return res.status(400).json({
        success: false,
        data: null,
        message: "Booking is already cancelled",
      });
    }

    booking.status = "cancelled";
    await booking.save();

    // ✅ Reset property status back to available
    await Property.findByIdAndUpdate(booking.property, { status: "available" });

    return res.status(200).json({
      success: true,
      data: booking,
      message: "Booking cancelled successfully",
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};

// DELETE a booking
const deleteBooking = async (req, res) => {
  try {
    const booking = await Booking.findByIdAndDelete(req.params.id);

    if (!booking) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Booking not found",
      });
    }

    // ✅ Reset property status back to available
    await Property.findByIdAndUpdate(booking.property, { status: "available" });

    return res.status(200).json({
      success: true,
      data: null,
      message: "Booking deleted successfully",
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};

// GET Bookings for My Properties (for property owners)
const getPropertyBookings = async (req, res) => {
  try {
    // Find all properties owned by this user first
    const myProperties = await Property.find({ owner: req.user.id }).select("_id");
    const propertyIds = myProperties.map((p) => p._id);

    const bookings = await Booking.find({ property: { $in: propertyIds } })
      .populate("user", "firstName lastName email phoneNumber")
      .populate("property", "title location mainImage price")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: bookings,
      message: "Property bookings fetched successfully",
    });
  } catch (err) {
    return res.status(500).json({
      success: false,
      data: null,
      message: err.message,
    });
  }
};
module.exports = {
  getBookings,
  getBookingById,
  createBooking,
  cancelBooking,
  deleteBooking,
  getMyBookings,
  getPropertyBookings,
};
