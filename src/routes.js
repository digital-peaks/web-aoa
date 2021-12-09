const express = require("express");

const router = express.Router();

// Add another ./module/module.routes file here:

router.use("/", require("./job/job.routes"));
router.use("/", require("./file/file.routes"));

module.exports = router;
