const express = require("express");
const asyncHandler = require("express-async-handler");
const JobFileService = require("./job-file.service");
const auth = require("../../auth/auth.middleware");

const router = express.Router();

/**
 * @swagger
 * /jobs/{id}/files:
 *   get:
 *     summary: Get a list of job files.
 *     tags: [Jobs]
 *     security:
 *       - BearerAuth: []
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
 *                type: array
 *                items:
 *                  $ref: '#/components/schemas/JobFile'
 *       "401":
 *         $ref: '#/components/responses/UnauthorizedException'
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/jobs/:jobId/files/",
  auth(),
  asyncHandler(async (req, res) => {
    const result = await JobFileService.getJobFiles(req.params.jobId, req.user);
    res.json(result);
  })
);

/**
 * @swagger
 * /jobs/{id}/files/{name}:
 *   get:
 *     summary: Get job file by name.
 *     tags: [Jobs]
 *     security:
 *       - BearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Job id
 *       - in: path
 *         name: name
 *         required: true
 *         schema:
 *           type: string
 *         description: Job file name
 *       - in: query
 *         name: download
 *         required: false
 *         schema:
 *           type: boolean
 *           default: false
 *         description: Force to download the file.
 *     responses:
 *       "200":
 *         description: OK
 *       "401":
 *         $ref: '#/components/responses/UnauthorizedException'
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/jobs/:jobId/files/:name",
  auth(),
  asyncHandler(async (req, res) => {
    const { download } = req.query;
    await JobFileService.getJobFile(
      res,
      req.params.jobId,
      req.params.name,
      req.user,
      {
        download,
      }
    );
  })
);

module.exports = router;
