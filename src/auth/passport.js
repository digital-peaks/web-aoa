const { Strategy: JwtStrategy, ExtractJwt } = require("passport-jwt");
const User = require("../user/user.model");

// loads environment variables from a .env
require("dotenv").config();

// This file is mostly inspired by
// https://github.com/hagopj13/node-express-boilerplate/blob/master/src/config/passport.js

const jwtOptions = {
  secretOrKey: process.env.JWT_SECRET || "",
  jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
};

const jwtVerify = async (payload, done) => {
  try {
    const user = await User.findById(payload.id);
    if (!user) {
      return done(null, false);
    }
    done(null, user);
  } catch (error) {
    done(error, false);
  }
};

const jwtStrategy = new JwtStrategy(jwtOptions, jwtVerify);

module.exports = {
  jwtStrategy,
};
