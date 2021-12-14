const express = require("express");
const asyncHandler = require("express-async-handler");
const JobService = require("./job.service");

const router = express.Router();

// Add express request handlers:

/**
 * @swagger
 * tags:
 *   name: Jobs
 */

/**
 * @swagger
 * /jobs:
 *   post:
 *     summary: Create a job
 *     tags: [Jobs]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - use_lookup
 *               - resolution
 *               - cloud_cover
 *               - start_timestamp
 *               - end_timestamp
 *               - sampling_strategy
 *             properties:
 *              name:
 *                type: string
 *              use_lookup:
 *                type: boolean
 *              resolution:
 *                type: number
 *              cloud_cover:
 *                type: number
 *              start_timestamp:
 *                type: date-time
 *              end_timestamp:
 *                type: date-time
 *              sampling_strategy:
 *                type: string
 *              use_pretrained_model:
 *                type: boolean
 *             example:
 *               name: "Job name"
 *               use_lookup: false
 *               resolution: 10
 *               cloud_cover: 15
 *               start_timestamp: "2020-01-01T00:00:00.000Z"
 *               end_timestamp: "2020-06-01T00:00:00.000Z"
 *               sampling_strategy: "regular"
 *               use_pretrained_model: false
 *     responses:
 *       "201":
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *                $ref: '#/components/schemas/Job'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.post(
  "/jobs",
  // The asyncHandler helps us to use await inside `(req, res) => { ... }`
  // And it catches errors properly.
  // Recommend to use it for every request handler!
  asyncHandler(async (req, res) => {
    // Please keep this logic simple and just call the service function.
    // Validations or MongoDB requests should run inside the service.
    const result = await JobService.createJob(req.body);
    res.status(201).json(result);
  })
);

/**
 * @swagger
 * /jobs/{id}:
 *   get:
 *     summary: Get job by id.
 *     tags: [Jobs]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Job id
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *                $ref: '#/components/schemas/Job'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/jobs/:jobId",
  asyncHandler(async (req, res) => {
    const result = await JobService.getJob(req.params.jobId);
    res.json(result);
  })
);

/**
 * @swagger
 * /jobs:
 *   put:
 *     summary: Update job.
 *     tags: [Jobs]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Job'
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *                $ref: '#/components/schemas/Job'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.put(
  "/jobs",
  asyncHandler(async (req, res) => {
    const result = await JobService.updateJob(req.body);
    res.json(result);
  })
);

/**
 * @swagger
 * /jobs:
 *   get:
 *     summary: Get all jobs
 *     tags: [Jobs]
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *                type: array
 *                items:
 *                  $ref: '#/components/schemas/Job'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/jobs",
  asyncHandler(async (req, res) => {
    const result = await JobService.getJobs();
    res.json(result);
  })
);

/**
 * @swagger
 * /jobs/{id}:
 *   delete:
 *     summary: Delete job by id.
 *     tags: [Jobs]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Job id
 *     responses:
 *       "200":
 *         description: No content
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.delete(
  "/jobs/:jobId",
  asyncHandler(async (req, res) => {
    const result = await JobService.deleteJob(req.params.jobId);
    res.json(result);
  })
);

module.exports = router;
