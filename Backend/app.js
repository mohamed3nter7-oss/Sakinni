const { MongoClient, ServerApiVersion } = require("mongodb");
const mongoose = require("mongoose");
const express = require("express");

const morgan = require("morgan");

const app = express();
app.use(morgan("dev"));

app.use(express.json());

// connection url
const uri = "mongodb+srv://kokooromany_db_user:<29XTMDTau6EukOp7>@sakinnidb.jmoubu2.mongodb.net/";

// Create a MongoClient with a MongoClientOptions object to set the Stable API version
const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

async function run() {
  try {
    // Connect the client to the server	(optional starting in v4.7)
    await client.connect();
    // Send a ping to confirm a successful connection
    await client.db("admin").command({ ping: 1 });
    console.log("Pinged your deployment. You successfully connected to MongoDB!");
  } finally {
    // Ensures that the client will close when you finish/error
    await client.close();
  }
}
run().catch(console.dir);


//Database Name
const dbName = "sakinni";
let usersCollection;
async function connectDB() {
  await client.connect();
  console.log("Connected successfully to server");
  const db = client.db(dbName);
  usersCollection = db.collection("users");
}

module.exports = app;