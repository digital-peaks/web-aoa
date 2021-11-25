const BaseException = require("./BaseException");

class UnauthorizedException extends BaseException {
  constructor(args) {
    super(args);
    this.statusCode = 401;
    this.name = "Unauthorized";
  }
}

module.exports = UnauthorizedException;
