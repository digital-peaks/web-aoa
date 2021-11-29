const BaseException = require("./BaseException");

class BadRequestException extends BaseException {
  constructor(args) {
    super(args);
    this.statusCode = 400;
    this.name = "Bad Request";
  }
}

module.exports = BadRequestException;
