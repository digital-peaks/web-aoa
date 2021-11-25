const mongoose = require("mongoose");
const { toJSON, paginate } = require("../utils/mongoose");

const jobSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  created: { type: Date, default: Date.now },
});

jobSchema.plugin(toJSON);
jobSchema.plugin(paginate);

/**
 * @typedef Job
 */
const Job = mongoose.model("Job", jobSchema);

module.exports = Job;
