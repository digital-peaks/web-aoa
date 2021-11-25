const express = require("express");
const asyncHandler = require("express-async-handler");
const JobService = require("./job.service");

const router = express.Router();

// Add express request handlers:

router.post(
  "/jobs",
  // The asyncHandler helps us to use await inside `(req, res) => { ... }`
  // And it catches errors properly.
  // Recommend to use it for every request handler!
  asyncHandler(async (req, res) => {
    // Please keep this logic simple and just call the service function.
    // Validations or MongoDB requests should run inside the service.
    const result = await JobService.createJob(req.body);
    res.json(result);
  })
);

router.get(
  "/jobs/:jobId",
  asyncHandler(async (req, res) => {
    const result = await JobService.getJob(req.params.jobId);
    res.json(result);
  })
);

router.get(
  "/jobs",
  asyncHandler(async (req, res) => {
    const result = await JobService.getJobs();
    res.json(result);
  })
);

module.exports = router;
