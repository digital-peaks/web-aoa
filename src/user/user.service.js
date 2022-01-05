const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const User = require("./user.model");
const {
  BadRequestException,
  UnauthorizedException,
  NotFoundException,
} = require("../utils/exceptions");
const logger = require("../utils/logger");
const { generateFingerprint } = require("./utils");

// loads environment variables from a .env
require("dotenv").config();

const PASSWORD_HASH_SALT_ROUND = 10;

/**
 * Check password.
 * Will throw an error, if the password does not comply with the guidelines.
 * @param {string} password
 */
const checkPassword = (password) => {
  if (!password || password.length < 8) {
    throw new BadRequestException(
      "Password must have a minimum length of 8 characters"
    );
  }

  if (!password.match(/\d/) || !password.match(/[a-zA-Z]/)) {
    throw new BadRequestException(
      "Password must contain at least one letter and one number"
    );
  }
};

/**
 * Create a new user.
 * @param {object} body
 * @returns
 */
const login = async (body) => {
  const user = await User.findOne({ email: body.email });

  if (!user) {
    throw new UnauthorizedException("Email or password incorrect");
  }

  let isPasswordCorrect = false;
  try {
    isPasswordCorrect = await bcrypt.compare(body.password, user.password);
  } catch (err) {
    logger.error(err);
    throw new UnauthorizedException("Email or password incorrect");
  }

  if (!isPasswordCorrect) {
    logger.warn(`Incorrect password for account: ${user.email}`);
    throw new UnauthorizedException("Email or password incorrect");
  }

  const fingerprint = generateFingerprint(user);

  const token = jwt.sign(
    { id: user.id, fingerprint },
    process.env.JWT_SECRET || ""
  );

  logger.info(`Generated JWT for account: ${user.email}`);

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

  checkPassword(body.password);

  logger.info("Create new user");

  user.password = bcrypt.hashSync(body.password, PASSWORD_HASH_SALT_ROUND);

  return user.save();
};

/**
 * Get all users.
 * @returns
 */
const getUsers = async () => {
  const users = await User.find().sort({ created: "desc" });
  return users;
};

/**
 * Update user
 * @param {User} user
 * @returns
 */
const updateUser = async (body) => {
  await new User(body).validate();

  // Pick only update able fields:
  const data = {
    name: body.name,
    email: body.email,
  };

  // check password and hash it
  if (body.password) {
    checkPassword(body.password);
    data.password = bcrypt.hashSync(body.password, PASSWORD_HASH_SALT_ROUND);
  }

  const { matchedCount } = await User.updateOne({ _id: body.id }, data);

  if (matchedCount === 0) {
    throw new NotFoundException("Unable to update unknown user");
  }

  return User.findOne({ _id: body.id });
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
  updateUser,
  deleteUser,
};
