const fs = require("fs");
const { spawn } = require("child_process");
const Job = require("./job.model");
const { NotFoundException } = require("../utils/exceptions");
const logger = require("../utils/logger");

/**
 * Create a new job.
 * @param {object} body
 * @returns
 */
const createJob = async (body) => {
  // Mongoose API documentation - Model:
  // https://mongoosejs.com/docs/api/model.html

  // If validation fails, the error will handled as 400
  await new Job(body).validate();

  const job = await Job.create(body);

  // TODO: Dynamic job folder
  // const jobFolder = `${job.id}`;
  const jobFolder = "1234567";
  const jobPath = `/app/r/${jobFolder}`;

  await fs.promises.mkdir(jobPath);
  await fs.promises.copyFile("/app/r/aoi.geojson", `${jobPath}/aoi.geojson`);
  await fs.promises.copyFile(
    "/app/r/samplePolygons.geojson",
    `${jobPath}/samplePolygons.geojson`
  );

  // Run R script:
  const ls = spawn("R", ["-e", 'source("/app/aoa_script.R")']);

  ls.stdout.on("data", (data) => {
    logger.info(`stdout: ${data}`);
  });

  ls.stderr.on("data", (data) => {
    logger.info(`stderr: ${data}`);
  });

  ls.on("close", (code) => {
    logger.info(`child process exited with code ${code}`);
  });

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
 * Update existing job.
 * @param {object} body
 * @returns
 */
const updateJob = async (body) => {
  await new Job(body).validate();

  const { matchedCount } = await Job.updateOne({ _id: body.id }, body);

  if (matchedCount === 0) {
    throw new NotFoundException("Unable to update unknown job");
  }

  return Job.findOne({ _id: body.id });
};

/**
 * Get all jobs.
 * @returns
 */
const getJobs = async () => {
  const jobs = await Job.find().sort({ created: "desc" });
  return jobs;
};

/**
 * Delete job.
 * @param {string} id
 * @returns
 */
const deleteJob = async (id) => {
  return Job.deleteOne({ _id: id });
};

module.exports = {
  createJob,
  getJob,
  updateJob,
  getJobs,
  deleteJob,
};
