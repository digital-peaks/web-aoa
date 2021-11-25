const express = require("express");

const router = express.Router();

// Add another ./module/module.routes file here:

router.use("/", require("./job/job.routes"));

module.exports = router;
