// routes/users.js
const app = require("../app");
const express = require("express");
const router = express.Router();
const { getAllUsers,createUser,getUserById,deleteUser} = require("../controllers/userController");


app.get("/api/users", getAllUsers);
app.get("/api/users/:id", getUserById);
app.post("/api/users", createUser);
app.delete("/api/users/:id", deleteUser);
module.exports = router;