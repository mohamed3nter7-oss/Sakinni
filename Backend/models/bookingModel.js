const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  propertyId: { 
    type: String, 
    required: [true, 'Property ID is required'] 
  },
  userId: { 
    type: String, 
    required: [true, 'User ID is required'] 
  },
  title: { 
    type: String,
    required: [true, 'Title is required'],
    maxlength: [100, 'Title cannot exceed 100 characters'],
    trim: true,
  },
  mainImage: { 
    type: String,
    default: '',
  },
  price: { 
    type: Number,
    required: [true, 'Price is required'],
    min: [0, 'Price cannot be negative'],
  },
  location: { 
    type: String,
    required: [true, 'Location is required'],
    trim: true,
  },
  startDate: { type: Date },
  endDate:   { type: Date },
  status: { 
    type: String, 
    enum: {
      values: ['pending', 'confirmed', 'cancelled'],
      message: 'Status must be pending, confirmed, or cancelled'
    },
    default: 'pending' 
  },
}, { timestamps: true });

module.exports = mongoose.model('Booking', bookingSchema, 'bookings');