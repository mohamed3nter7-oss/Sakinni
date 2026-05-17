require('dotenv').config();
const dotenv = require("dotenv");
dotenv.config();

const app = require("./app");
const connectDB = require("./config/db");

connectDB();

const PORT =  5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});