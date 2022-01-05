const mongoose = require("mongoose");
const validator = require("validator");
const { toJSON, paginate } = require("../utils/mongoose");

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
    validate(value) {
      if (!validator.isEmail(value)) {
        throw new Error("Invalid email");
      }
    },
  },
  password: {
    type: String,
    trim: true,
    private: true, // used by the toJSON plugin
  },
  created: { type: Date, default: Date.now },
});

// Please use these plugins for a new model.
// For more information please see comments in the implementation.
userSchema.plugin(toJSON);
userSchema.plugin(paginate);

// Mongoose documentation - Models:
// https://mongoosejs.com/docs/models.html#compiling
/**
 * @typedef User
 */
const User = mongoose.model("User", userSchema);

module.exports = User;
