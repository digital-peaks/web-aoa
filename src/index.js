const mongoose = require("mongoose");
const logger = require("./utils/logger");
const app = require("./app");

// loads environment variables from a .env
require("dotenv").config();

const { EXPRESS_PORT, MONGODB_CONNECTION_STRING } = process.env;

let server;

const establishServer = () => {
  logger.info("Connected to MongoDB");
  server = app.listen(EXPRESS_PORT, () => {
    logger.info(`Listening to port ${EXPRESS_PORT}`);
  });
};

const connectToMongo = async () => {
  mongoose
    .connect(MONGODB_CONNECTION_STRING)
    .then(() => {
      establishServer();
    })
    .catch((err1) => {
      logger.error("Failed to connect to mongo - retrying in 10 sec");
      logger.error(err1);
      setTimeout(() => {
        // retry
        mongoose
          .connect(MONGODB_CONNECTION_STRING)
          .then(() => {
            establishServer();
          })
          .catch((err2) => {
            logger.error("Finally failed to connect to mongo");
            logger.error(err2);
          });
      }, 10000);
    });
};
connectToMongo();

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
