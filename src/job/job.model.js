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
