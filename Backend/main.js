const {mongoClient } = require('mongodb');

const uri = "mongodb://localhost:27017/Sakinni";
const mongoose = require('mongoose');
const express = require('express');
const app = express();

module.exports = { app }; 

