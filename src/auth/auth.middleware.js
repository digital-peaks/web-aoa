const passport = require("passport");
const { UnauthorizedException } = require("../utils/exceptions");

/**
 * Helper to verify the authenticate callback and handling errors.
 * @param {object} req
 * @param {function} resolve
 * @param {function} reject
 * @returns
 */
const verifyCallback = (req, resolve, reject) => async (err, user, info) => {
  if (err || info || !user) {
    return reject(new UnauthorizedException("Invalid token"));
  }
  req.user = user;

  resolve();
};

/**
 * Returns an express middleware function which calls the passport.authenticate function.
 * @returns
 */
const auth = () => async (req, res, next) => {
  return new Promise((resolve, reject) => {
    passport.authenticate(
      "jwt",
      { session: false },
      verifyCallback(req, resolve, reject)
    )(req, res, next);
  })
    .then(() => next())
    .catch((err) => next(err));
};

module.exports = auth;
