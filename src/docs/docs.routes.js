const express = require("express");
const swaggerJsdoc = require("swagger-jsdoc");
const swaggerUi = require("swagger-ui-express");
const swaggerDefinition = require("./swaggerDef");

const router = express.Router();

const specs = swaggerJsdoc({
  swaggerDefinition,
  // put it in the right order:
  apis: ["src/docs/*.yaml", "src/job/job.routes.js", "src/**/*.routes.js"],
});

router.use("/docs", swaggerUi.serve);
router.get(
  "/docs",
  swaggerUi.setup(specs, {
    explorer: true,
  })
);

module.exports = router;
