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
  } else {
    // Unknown or unhandled exception/error.
    const unexpected = new InternalServerErrorException(
      "Unexpected server error"
    );
    unexpected.stack = error.stack;

    logger.error(unexpected);

    res.status(unexpected.statusCode);
    res.json(unexpected.toJSON());
  }
};

module.exports = requestErrorHandler;
