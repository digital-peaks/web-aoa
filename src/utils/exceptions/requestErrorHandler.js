const mongoose = require("mongoose");
const logger = require("../logger");

const {
  BadRequestException,
  UnauthorizedException,
  NotFoundException,
  InternalServerErrorException,
} = require("./index");

/**
 * Middleware which handles errors and will return them as a proper JSON format.
 */
// eslint-disable-next-line no-unused-vars
const requestErrorHandler = (error, req, res, next) => {
  if (
    // Please add your new exception here:
    error instanceof BadRequestException ||
    error instanceof UnauthorizedException ||
    error instanceof NotFoundException ||
    error instanceof InternalServerErrorException
  ) {
    logger.error(error);

    res.status(error.statusCode);
    res.json(error.toJSON());
  } else if (
    error instanceof mongoose.Error.ValidationError ||
    error instanceof mongoose.Error.CastError
  ) {
    // Handle mongoose validation or cast errors:
    let validationError;
    if (error instanceof mongoose.Error.CastError) {
      const message =
        error.kind === "ObjectId"
          ? "The id must be a string of 12 bytes or a string of 24 hex characters"
          : error.reason || "Cast Error";
      validationError = new BadRequestException(message);
    } else {
      validationError = new BadRequestException(error.errors);
    }

    const response = validationError.toJSON();
    delete response.stack;
    logger.warn(JSON.stringify(response, null, 2));

    validationError.stack = error.stack;

    res.status(validationError.statusCode);
    res.json(validationError.toJSON());
  } else {
    // Handle unknown or unhandled exceptions/errors:
    const unexpected = new InternalServerErrorException(
      "Unexpected server error"
    );

    logger.error(error.stack);
    const response = unexpected.toJSON();
    delete response.stack;
    logger.error(JSON.stringify(response, null, 2));

    unexpected.stack = error.stack;

    res.status(unexpected.statusCode);
    res.json(unexpected.toJSON());
  }
};

module.exports = requestErrorHandler;
