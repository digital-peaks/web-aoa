const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const User = require("./user.model");
const {
  BadRequestException,
  UnauthorizedException,
} = require("../utils/exceptions");
const logger = require("../utils/logger");

// loads environment variables from a .env
require("dotenv").config();

/**
 * Create a new user.
 * @param {object} body
 * @returns
 */
const login = async (body) => {
  const user = await User.findOne({ email: body.email, deleted: null });

  if (!user) {
    throw new UnauthorizedException("Email or password incorrect");
  }

  try {
    await bcrypt.compare(body.password, user.password);
  } catch (err) {
    throw new UnauthorizedException("Email or password incorrect");
  }

  const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET || "");

  return { token };
};

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
    throw new BadRequestException(
      "Password must have a minimum length of 8 characters"
    );
  }

  if (!body.password.match(/\d/) || !body.password.match(/[a-zA-Z]/)) {
    throw new BadRequestException(
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
  login,
  createUser,
  getUsers,
  deleteUser,
};
