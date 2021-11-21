const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");

require("dotenv").config();

const app = express();

// Set file size limit to 5mb
app.use(bodyParser.json({ limit: "5mb", type: "application/json" }));

app.use(cors());

app.get("/info", function (req, res) {
  res.send(`Environment: ${process.env.NODE_ENV || "-"}`);
});

module.exports = app;
