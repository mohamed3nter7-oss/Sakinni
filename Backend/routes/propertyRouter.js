const express = require("express");
const router = express.Router();

const {
  getAllProperties,
  getPropertyById,
  createProperty,
  updateProperty,
  deleteProperty,
} = require("../Controllers/propertyController");

// GET /property
router.get("/", getAllProperties);

// GET /property/:id
router.get("/:id", getPropertyById);

// POST /property
router.post("/", createProperty);

// PUT /property/:id
router.put("/:id", updateProperty);

// PATCH /property/:id
router.patch("/:id", updateProperty);

// DELETE /property/:id
router.delete("/:id", deleteProperty);

module.exports = router;