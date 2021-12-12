const mongoose = require("mongoose");
const { toJSON, paginate } = require("../utils/mongoose");

const fileSchema = new mongoose.Schema({
  extension: {
    type: String,
    required: true,
    trim: true,
  },
  original_name: {
    type: String,
    required: true,
    trim: true,
  },
  mime_type: {
    type: String,
    required: true,
  },
  size: {
    type: Number,
    required: true,
  },
  user_id: {
    type: Number,
    // TODO: Should be a real user id in future
    default: 0,
    // Faster access with index:
    index: true,
  },
  created: { type: Date, default: Date.now },
});

fileSchema.plugin(toJSON);
fileSchema.plugin(paginate);

/**
 * @typedef File
 */
const File = mongoose.model("File", fileSchema);

module.exports = File;
