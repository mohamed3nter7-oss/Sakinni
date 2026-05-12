const mongoose = require("mongoose");

async function connectDB() {
  await mongoose.connect("mongodb+srv://kokooromany_db_user:29XTMDTau6EukOp7@sakinnidb.jmoubu2.mongodb.net/");
  console.log("MongoDB connected");
}

module.exports = connectDB;