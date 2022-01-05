const { UnauthorizedException } = require("../utils/exceptions");

// loads environment variables from a .env
require("dotenv").config();

const API_KEY = process.env.API_KEY || "";

/**
 * Returns an express middleware function which checks the "x-api-key" header.
 * @returns
 */
const apiKey = () => async (req, res, next) => {
  const xApiKey = req.get("x-api-key") || "";

  if (xApiKey !== API_KEY) {
    next(new UnauthorizedException("Invalid X-API-KEY"));
  }

  next();
};

module.exports = apiKey;
