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
  area_of_interest: {
    type: Object,
    required: true,
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
  samples_class: {
    type: String,
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
  /**
   * Job is finished.
   * Whether with status success or terminated by an error.
   */
  finished: { type: Date },
  /**
   * Indicates the status of the job.
   * Should be: "running", "error", "success"
   */
  status: { type: String, default: "running" },
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
