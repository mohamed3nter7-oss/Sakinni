const Payment = require("../models/paymentModel");


// GET ALL PAYMENTS
const getPayments = async (req, res) => {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;
    if (req.query.paymentMethod) filter.paymentMethod = req.query.paymentMethod;

    const payments = await Payment.find(filter)
      .populate("user", "firstName lastName email")       // ✅ add populate
      .populate("property", "title location")             // ✅ add populate
      .populate("booking")                                // ✅ add populate
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: payments,
      message: "Payments fetched successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

// GET PAYMENT BY ID
const getPaymentById = async (req, res) => {
  try {
    const payment = await Payment.findById(req.params.id)
      .populate("user", "firstName lastName email")
      .populate("property", "title location mainImage")
      .populate("booking");

    if (!payment) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Payment not found",
      });
    }

    // ✅ Only the owner of this payment or admin can view it
    const isOwner = payment.user._id.toString() === req.user.id.toString();
    const isAdmin = req.user.userRole === "admin";

    if (!isOwner && !isAdmin) {
      return res.status(403).json({
        success: false,
        data: null,
        message: "You are not allowed to view this payment",
      });
    }

    return res.status(200).json({
      success: true,
      data: payment,
      message: "Payment fetched successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};



// CREATE PAYMENT
const createPayment = async (req, res) => {
  try {
    const payment = await Payment.create({
      ...req.body,
      user: req.user.id, // ✅ auto-set from token, not from req.body
      processedAt: req.body.status === "completed" ? new Date() : null,
    });

    await payment.populate([
      { path: "user", select: "firstName lastName email" },
      { path: "property", select: "title location" },
      { path: "booking" },
    ]);

    return res.status(201).json({
      success: true,
      data: payment,
      message: "Payment created successfully",
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


// UPDATE PAYMENT
const updatePayment = async (req, res) => {
  try {
    const { status } = req.body;

    const payment = await Payment.findByIdAndUpdate(
      req.params.id,
      {
        status,
        processedAt: status === "completed" ? new Date() : null,
      },
      { new: true, runValidators: true }
    )
      .populate("user", "firstName lastName email")
      .populate("property", "title location")
      .populate("booking");

    if (!payment) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Payment not found",
      });
    }

    return res.status(200).json({
      success: true,
      data: payment,
      message: "Payment status updated successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

// Get My Paymenst
const getMyPayments = async (req, res) => {
  try {
    const payments = await Payment.find({ user: req.user.id })
      .populate("property", "title location mainImage")
      .populate("booking")
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: payments,
      message: "Your payments fetched successfully",
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};


// DELETE PAYMENT
const deletePayment = async (req, res) => {

  try {

    const payment = await Payment.findByIdAndDelete(req.params.id);

    if (!payment) {

      return res.status(404).json({
        success: false,
        message: "Payment not found",
      });
    }

   return res.status(200).json({
  success: true,
  data: null,
  message: "Payment deleted successfully",
});

  } catch (error) {

    res.status(500).json({
      success: false,
      message: error.message,
    });

  }
};


module.exports = {
  getPayments,
  getPaymentById,
  createPayment,
  updatePayment,
  deletePayment,
  getMyPayments,
};