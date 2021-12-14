const fs = require("fs");
const path = require("path");
// eslint-disable-next-line
const child_process = require("child_process");
const Job = require("./job.model");
const {
  NotFoundException,
  BadRequestException,
  InternalServerErrorException,
} = require("../utils/exceptions");
const logger = require("../utils/logger");
const { convertForR } = require("./utils");

const MAX_UPLOAD_SIZE_MB =
  Number.parseInt(process.env.FILES_MAX_UPLOAD_SIZE_MB, 10) || 10;

const SAMPLES_MIME_TYPES = ["application/geo+json", "application/json"];

const MODEL_MIME_TYPES = [""];

const JOBS_FOLDER = path.join(__dirname, "/../../jobs");

const maxUploadFileSizeBytes = 1024 * 1024 * MAX_UPLOAD_SIZE_MB;

/**
 * Delete job.
 * @param {string} id
 * @returns
 */
const deleteJob = async (id) => {
  // delete from MongoDB
  const deleted = await Job.deleteOne({ _id: id });

  // Delete relevant files
  const jobPath = path.join(JOBS_FOLDER, id);
  fs.promises.rm(jobPath, { force: true, recursive: true });

  return deleted;
};

/**
 * Create a new job.
 * @param {object} body
 * @returns
 */
const createJob = async (bodyRaw, files, isDemo = true) => {
  // Parse and validate body
  const body = JSON.parse(bodyRaw);
  await new Job(body).validate();

  const [samplesFile] = files.samples || [];
  const [modelFile] = files.model || [];

  // Validate sample file
  if (samplesFile) {
    logger.info(`Samples file size: ${samplesFile.size}`);
    if (samplesFile.size > maxUploadFileSizeBytes) {
      throw new BadRequestException(
        `Maximum upload file size: ${MAX_UPLOAD_SIZE_MB} MB`
      );
    }
    logger.info(`Samples file MIME-Type: ${samplesFile.mimetype}`);
    if (!SAMPLES_MIME_TYPES.includes(samplesFile.mimetype)) {
      throw new BadRequestException(
        `MIME-Type not allowed for samples. Allowed: ${SAMPLES_MIME_TYPES.join(
          ", "
        )}`
      );
    }
  }

  // Validate model file
  if (modelFile) {
    logger.info(`Model file size: ${modelFile.size}`);
    if (modelFile.size > maxUploadFileSizeBytes) {
      throw new BadRequestException(
        `Maximum upload file size: ${MAX_UPLOAD_SIZE_MB} MB`
      );
    }
    logger.info(`Model file MIME-Type: ${modelFile.mimetype}`);
    if (!MODEL_MIME_TYPES.includes(modelFile.mimetype)) {
      throw new BadRequestException(
        `MIME-Type not allowed for model. Allowed: ${MODEL_MIME_TYPES.join(
          ", "
        )}`
      );
    }
  }

  const job = await Job.create(body);

  const jobFolder = `${job.id}`;
  const jobPath = path.join(JOBS_FOLDER, jobFolder);

  const parametersR = convertForR(job);
  logger.info(`R parameters: ${JSON.stringify(parametersR)}`);

  try {
    // eslint-disable-next-line
    await fs.promises.mkdir(jobPath);

    // Just passing the job id which is generated by MongoDB:
    // eslint-disable-next-line security/detect-non-literal-fs-filename
    await fs.promises.writeFile(
      `${jobPath}/job_param.json`,
      // Stringify and format it with spaces:
      JSON.stringify(parametersR, null, 2),
      "utf8"
    );
  } catch (err) {
    logger.error(err);
    // CLEANUP:
    await deleteJob(job.id);
    const serverErr = InternalServerErrorException(
      "Unable to create job folder with params"
    );
    serverErr.stack = err.stack;
    throw serverErr;
  }

  if (isDemo) {
    try {
      // Copy data for demo:
      await fs.promises.copyFile(
        "/app/r/test/aoi.geojson",
        `${jobPath}/aoi.geojson`
      );
      await fs.promises.copyFile(
        "/app/r/test/samples.geojson",
        `${jobPath}/samples.geojson`
      );
    } catch (err) {
      logger.error(err);
      // CLEANUP:
      await deleteJob(job.id);
      const serverErr = InternalServerErrorException(
        "Unable to copy demo files"
      );
      serverErr.stack = err.stack;
      throw serverErr;
    }
  } else {
    // Copy uploaded files into the job folder
    try {
      // eslint-disable-next-line security/detect-non-literal-fs-filename
      await fs.promises.writeFile(
        path.join(jobPath, "aoi.geojson"),
        // Stringify and format it with spaces:
        JSON.stringify(job.area_of_interest, null, 2),
        "utf8"
      );

      if (samplesFile) {
        // eslint-disable-next-line security/detect-non-literal-fs-filename
        await fs.promises.writeFile(
          path.join(jobPath, "samples.geojson"),
          samplesFile.buffer
        );
      }

      if (modelFile) {
        // eslint-disable-next-line security/detect-non-literal-fs-filename
        await fs.promises.writeFile(
          path.join(jobPath, "model.rds"),
          modelFile.buffer
        );
      }
    } catch (err) {
      logger.error(err);
      // CLEANUP:
      await deleteJob(job.id);
      const serverErr = InternalServerErrorException("Unable to save files");
      serverErr.stack = err.stack;
      throw serverErr;
    }
  }

  // Run R script:
  const script = child_process.spawn("R", [
    "-e",
    'source("/app/r/aoa_script.R")',
    "--args",
    jobFolder,
  ]);

  script.stdout.on("data", (data) => {
    logger.info(`stdout: ${data}`);
  });

  script.stderr.on("data", (data) => {
    logger.info(`stderr: ${data}`);
  });

  script.on("close", (code) => {
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

module.exports = {
  createJob,
  getJob,
  updateJob,
  getJobs,
  deleteJob,
};
