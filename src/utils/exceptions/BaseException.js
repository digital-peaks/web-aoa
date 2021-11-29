/**
 * Every Exceptions needs to extend from this Class.
 */
class BaseException extends Error {
  constructor(message = "", ...args) {
    // Do not print objects to error stack
    const messageClean = typeof message === "string" ? message : "";
    super(messageClean, ...args);

    this.statusCode = 500;
    this.name = "Error";
    this.description = message || "";
  }

  toJSON() {
    const json = {
      statusCode: this.statusCode,
      error: this.name,
      message: this.description,
    };
    if (process.env.NODE_ENV === "dev" && this.stack) {
      json.stack = this.stack;
    }
    return json;
  }
}

module.exports = BaseException;
