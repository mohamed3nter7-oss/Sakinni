const Property = require("../models/propertyModel");

exports.getAllProperties = async (req, res) => {
  try {
    const { city, area, minPrice, maxPrice, bedrooms, status } = req.query;

    const filter = {};

    if (city) filter["location.city"] = city;
    if (area) filter["location.area"] = area;
    if (status) filter.status = status;
    if (bedrooms) filter.bedrooms = Number(bedrooms);

    if (minPrice || maxPrice) {
      filter.price = {};
      if (minPrice) filter.price.$gte = Number(minPrice);
      if (maxPrice) filter.price.$lte = Number(maxPrice);
    }

    const properties = await Property.find(filter).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: properties,
      message: "Properties fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

exports.getPropertyById = async (req, res) => {
  try {
    const property = await Property.findById(req.params.id);

    if (!property) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Property not found",
      });
    }

    res.status(200).json({
      success: true,
      data: property,
      message: "Property fetched successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

exports.createProperty = async (req, res) => {
  try {
    const property = await Property.create(req.body);

    res.status(201).json({
      success: true,
      data: property,
      message: "Property created successfully",
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

exports.updateProperty = async (req, res) => {
  try {
    const property = await Property.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!property) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Property not found",
      });
    }

    res.status(200).json({
      success: true,
      data: property,
      message: "Property updated successfully",
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};

exports.deleteProperty = async (req, res) => {
  try {
    const property = await Property.findByIdAndDelete(req.params.id);

    if (!property) {
      return res.status(404).json({
        success: false,
        data: null,
        message: "Property not found",
      });
    }

    res.status(200).json({
      success: true,
      data: property,
      message: "Property deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      data: null,
      message: error.message,
    });
  }
};