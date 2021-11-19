const mongoose = require("mongoose");
const logger = require("./utils/logger");
const app = require("./app");

// loads environment variables from a .env
require("dotenv").config();

const { EXPRESS_PORT, MONGODB_CONNECTION_STRING } = process.env;

let server;
mongoose.connect(MONGODB_CONNECTION_STRING).then(() => {
  logger.info("Connected to MongoDB");
  server = app.listen(EXPRESS_PORT, () => {
    logger.info(`Listening to port ${EXPRESS_PORT}`);
  });
});

const exitHandler = () => {
  if (server) {
    server.close(() => {
      logger.info("Server closed");
      process.exit(1);
    });
  } else {
    process.exit(1);
  }
};

const unexpectedErrorHandler = (error) => {
  logger.error(error);
  exitHandler();
};

process.on("uncaughtException", unexpectedErrorHandler);
process.on("unhandledRejection", unexpectedErrorHandler);

process.on("SIGTERM", () => {
  logger.info("SIGTERM received");
  if (server) {
    server.close();
  }
});
