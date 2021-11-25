const BaseException = require("./BaseException");

class NotFoundException extends BaseException {
  constructor(args) {
    super(args);
    this.statusCode = 404;
    this.name = "Not Found";
  }
}

module.exports = NotFoundException;
