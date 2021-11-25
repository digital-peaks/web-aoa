const Job = require("./job.model");
const { NotFoundException } = require("../utils/exceptions");

/**
 * Create a new job.
 * @param {object} body
 * @returns
 */
const createJob = async (body) => {
  // TODO: Validate body against mongoose schema

  // Job is the model which we created in job.model.js
  // A model helps us to access data from the MongoDB easily.
  // Mongoose API documentation - Model:
  // https://mongoosejs.com/docs/api/model.html
  const job = await Job.create(body);
  return job;
};

/**
 * Get job by id.
 * @param {string} id
 * @returns
 */
const getJob = async (id) => {
  const job = await Job.findById(id);

  if (!job) {
    // Returns the request with a error code (in that case 404) with the given message.
    // They are pre defined exceptions in /src/utils/exceptions.
    throw new NotFoundException("Unable to find job");
  }

  return job;
};

/**
 * Get all jobs.
 * @returns
 */
const getJobs = async () => {
  const jobs = await Job.find().sort({ created: "desc" });
  return jobs;
};

module.exports = {
  createJob,
  getJob,
  getJobs,
};
