const crypto = require("crypto");

/**
 * Generate a fingerprint for the given user.
 *
 * This fingerprint is used to verify JWT tokens.
 * If the user changed the "email" or "password",
 * old JWT tokens will be not valid anymore.
 * @param {User} user
 * @returns
 */
const generateFingerprint = (user) => {
  // Concatenates 20 chars from the beginning and 20 from the end
  const passwordParts = user.password.slice(0, 20) + user.password.slice(-20);

  // Concatenate relevant values
  const value = `${user.email}_${passwordParts}_${user.id}`;

  return crypto.createHash("sha256").update(value).digest("hex");
};

module.exports = generateFingerprint;
