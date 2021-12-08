const { format } = require("date-fns");

/**
 * Convert job to the structure for the R script.
 * @param {Object} job
 * @returns
 */
const convertForR = (job) => {
  const defaultValues = {
    name: "Unnamed job",
    use_lookup: "false",
    resolution: 10,
    cloud_cover: 15,
    start_timestamp: "2020-01-01",
    end_timestamp: "2020-12-01",
    response: "class",
    samples: "samplePolygons.geojson",
    aoi: "aoi.geojson",
    sampling_strategy: "regular",
    obj_id: "PID",
    use_pretrained_model: "false",
    model: "model.rds",
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

  const {
    name,
    use_lookup,
    resolution,
    cloud_cover,
    sampling_strategy,
    use_pretrained_model,
    model,
  } = job;

  return {
    ...defaultValues,
    name,
    use_lookup,
    resolution,
    cloud_cover,
    sampling_strategy,
    use_pretrained_model,
    model,
    start_timestamp,
    end_timestamp,
  };
};

module.exports = convertForR;
