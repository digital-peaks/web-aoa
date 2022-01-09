const express = require("express");

const router = express.Router();

// Add another ./module/module.routes file here:

router.use("/", require("./job/job.routes"));
router.use("/", require("./docs/docs.routes"));
router.use("/", require("./user/user.routes"));

// Set subpath
const baseRouter = express.Router();
baseRouter.use("/api", router);

module.exports = baseRouter;
