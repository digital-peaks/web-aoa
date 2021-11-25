const BaseException = require("./BaseException");

class InternalServerErrorException extends BaseException {
  constructor(args) {
    super(args);
    this.statusCode = 500;
    this.name = "Internal Server Error";
  }
}

module.exports = InternalServerErrorException;
