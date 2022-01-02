const bcrypt = require("bcrypt");
const User = require("./user.model");
const { BadRequestException } = require("../utils/exceptions");
const logger = require("../utils/logger");

/**
 * Create a new user.
 * @param {object} body
 * @returns
 */
const createUser = async (body) => {
  const user = new User(body);
  // validation based on mongoose schema:
  await user.validate();

  if (!body.password || body.password.length < 8) {
    throw BadRequestException(
      "Password must have a minimum length of 8 characters"
    );
  }

  if (!body.password.match(/\d/) || !body.password.match(/[a-zA-Z]/)) {
    throw BadRequestException(
      "Password must contain at least one letter and one number"
    );
  }

  logger.info("Create new user");

  user.password = bcrypt.hashSync(body.password, 10);

  return user.save();
};

/**
 * Get all users.
 * @returns
 */
const getUsers = async () => {
  // select without password field
  const users = await User.find().select("-password").sort({ created: "desc" });
  return users;
};

/**
 * Delete user by id.
 * @param {string} id
 * @returns
 */
const deleteUser = async (id) => {
  const deleted = await User.deleteOne({ _id: id });
  return deleted;
};

module.exports = {
  createUser,
  getUsers,
  deleteUser,
};
