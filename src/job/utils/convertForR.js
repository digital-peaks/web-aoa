const { format } = require("date-fns");

/**
 * Convert job to the structure for the R script.
 * @param {Object} job
 * @returns
 */
const convertForR = (jobRaw) => {
  const defaultJob = {
    name: "Unnamed job",
    resolution: 10,
    cloud_cover: 15,
    start_timestamp: "2020-01-01",
    end_timestamp: "2020-12-01",
    samples_class: "class",
    sampling_strategy: "regular",
    obj_id: "PID",

    // Files:
    model: "model.rds",
    samples: "samples.geojson",
    aoi: "aoi.geojson",
  };

  const job = { ...defaultJob, ...jobRaw };

  // Format date-time to just a date:
  if (job.start_timestamp) {
    job.start_timestamp = format(new Date(job.start_timestamp), "yyyy-MM-dd");
  }
  if (job.end_timestamp) {
    job.end_timestamp = format(new Date(job.end_timestamp), "yyyy-MM-dd");
  }

  // Convert Boolean fields to string.
  // Because a string check is easier in R.
  job.use_lookup = job.use_lookup ? "true" : "false";
  job.use_pretrained_model = job.use_pretrained_model ? "true" : "false";

  if (job.area_of_interest) {
    // The AOI will be saved as aoi.json for the R script
    delete job.area_of_interest;
  }

  // Remove undefined values
  Object.keys(job).forEach((key) =>
    job[key] === undefined ? delete job[key] : {}
  );

  return job;
};

module.exports = convertForR;
