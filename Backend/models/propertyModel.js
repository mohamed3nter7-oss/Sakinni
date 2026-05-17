const mongoose = require("mongoose");

const locationSchema = new mongoose.Schema(
  {
    city: { type: String, required: true, trim: true },
    area: { type: String, required: true, trim: true },
    fullAddress: { type: String, required: true, trim: true },
  },
  { _id: false }
);

const propertySchema = new mongoose.Schema(
  {
    userId: {
      type: String,
      required: true,
      trim: true,
    },

    userName: {
      type: String,
      trim: true,
      default: "",
    },

    userImage: {
      type: String,
      default: "",
    },

    title: {
      type: String,
      required: true,
      trim: true,
      minlength: 3,
    },

    description: {
      type: String,
      required: true,
      trim: true,
    },

    price: {
      type: Number,
      required: true,
      min: 0,
    },

    priceDisplay: {
      type: String,
      trim: true,
    },

    location: {
      type: locationSchema,
      required: true,
    },

    bedrooms: {
      type: Number,
      default: 0,
      min: 0,
    },

    bathrooms: {
      type: Number,
      default: 0,
      min: 0,
    },

    kitchens: {
      type: Number,
      default: 0,
      min: 0,
    },

    balconies: {
      type: Number,
      default: 0,
      min: 0,
    },

    amenities: {
      type: [String],
      default: [],
    },

    isWifi: {
      type: Boolean,
      default: false,
    },

    images: {
      type: [String],
      default: [],
    },

    mainImage: {
      type: String,
      default: "",
    },

    rating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },

    status: {
      type: String,
      enum: ["available", "booked", "unavailable"],
      default: "available",
    },

    isPublished: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

propertySchema.index({ userId: 1 });
propertySchema.index({ price: 1 });
propertySchema.index({ "location.city": 1 });
propertySchema.index({ status: 1 });

module.exports = mongoose.model("Property", propertySchema);