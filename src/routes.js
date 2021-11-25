const express = require("express");

const router = express.Router();

router.use("/", require("./job/job.routes"));

module.exports = router;
