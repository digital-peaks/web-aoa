const Job = require("./job.model");
const { NotFoundException } = require("../utils/exceptions");

const createJob = async (body) => {
  // TODO: Validate body against mongoose schema
  const job = await Job.create(body);
  return job;
};

const getJob = async (id) => {
  const job = await Job.findById(id);

  if (!job) {
    throw new NotFoundException("Unable to find job");
  }

  return job;
};

const getJobs = async () => {
  const jobs = await Job.find().sort({ created: "desc" });
  return jobs;
};

module.exports = {
  createJob,
  getJob,
  getJobs,
};
