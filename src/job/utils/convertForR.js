const { format } = require("date-fns");

/**
 * Convert job to the structure for the R script.
 * @param {Object} job
 * @returns
 */
const convertForR = (jobRaw) => {
  const job = { ...jobRaw };

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

  // Format date-time to just a date:
  let start_timestamp = "2020-01-01";
  let end_timestamp = "2020-12-01";
  if (job.start_timestamp) {
    start_timestamp = format(new Date(job.start_timestamp), "yyyy-MM-dd");
  }
  if (job.end_timestamp) {
    end_timestamp = format(new Date(job.end_timestamp), "yyyy-MM-dd");
  }

  // Convert Boolean fields to string.
  // Because a string check is easier in R.
  job.use_lookup = job.use_lookup ? "true" : "false";
  job.use_pretrained_model = job.use_pretrained_model ? "true" : "false";

  // Remove undefined values
  Object.keys(job).forEach((key) =>
    job[key] === undefined ? delete job[key] : {}
  );

  if (job.area_of_interest) {
    delete job.area_of_interest;
  }

  return {
    ...defaultJob,
    ...job,
    start_timestamp,
    end_timestamp,
  };
};

module.exports = convertForR;
