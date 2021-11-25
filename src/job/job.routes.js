const express = require("express");
const asyncHandler = require("express-async-handler");
const JobService = require("./job.service");

const router = express.Router();

router.post(
  "/jobs",
  asyncHandler(async (req, res) => {
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
