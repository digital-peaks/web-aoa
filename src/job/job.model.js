const mongoose = require("mongoose");
const { toJSON, paginate } = require("../utils/mongoose");

// Mongoose documentation - Schemas:
// https://mongoosejs.com/docs/guide.html#definition
const jobSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  use_lookup: {
    type: Boolean,
    required: true,
  },
  resolution: {
    type: Number,
    required: true,
  },
  cloud_cover: {
    type: Number,
    required: true,
  },
  start_timestamp: {
    type: Date,
    required: true,
  },
  end_timestamp: {
    type: Date,
    required: true,
  },
  sampling_strategy: {
    type: String,
    required: true,
  },
  use_pretrained_model: {
    type: Boolean,
    default: false,
  },
  model: {
    type: String,
  },
  created: { type: Date, default: Date.now },
});

// Please use these plugins for a new model.
// For more information please see comments in the implementation.
jobSchema.plugin(toJSON);
jobSchema.plugin(paginate);

// Mongoose documentation - Models:
// https://mongoosejs.com/docs/models.html#compiling
/**
 * @typedef Job
 */
const Job = mongoose.model("Job", jobSchema);

module.exports = Job;
