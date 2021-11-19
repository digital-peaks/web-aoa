const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");

const app = express();

// Set file size limit to 5mb
app.use(bodyParser.json({ limit: "5mb", type: "application/json" }));

app.use(cors());

module.exports = app;
