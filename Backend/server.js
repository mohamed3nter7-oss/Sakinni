const app = require("./app.js");
const connectDB = require("./config/db.js");
const userRoutes = require("./routes/userRoutes.js");

app.use("/api/users", userRoutes);
connectDB();

app.listen(2000, () => {
  console.log("Server is running on port 2000");
});