const express = require("express");
const connectDB = require("./config/db");

const app = express();

app.use(express.json());

app.get("/", (req, res) => {
  res.send("API Running");
});

const startServer = async () => {
  await connectDB();
  app.listen(5000, () => {
    console.log("Server Running on port 5000");
  });
};

startServer();

const userRoutes = require("./routes/userRoutes");

app.use("/api/users", userRoutes);