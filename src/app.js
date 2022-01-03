const express = require("express");
const cors = require("cors");
const bodyParser = require("body-parser");
const passport = require("passport");
const { jwtStrategy } = require("./auth/passport");
const requestErrorHandler = require("./utils/exceptions/requestErrorHandler");

const routes = require("./routes");

const app = express();

// Set file size limit to 5mb
app.use(bodyParser.json({ limit: "5mb", type: "application/json" }));

app.use(cors());

// jwt authentication
app.use(passport.initialize());
passport.use("jwt", jwtStrategy);

// Register routes
app.use(routes);

// Handle errors and format them to a proper JSON format.
// Important: Needs to be the last middleware!
app.use(requestErrorHandler);

module.exports = app;
