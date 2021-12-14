const express = require("express");
const asyncHandler = require("express-async-handler");
const multer = require("multer");
const FileService = require("./file.service");

const upload = multer();

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Files
 */

/**
 * @swagger
 * /files:
 *   post:
 *     summary: Upload file.
 *     tags: [Files]
 *     consumes:
 *       - multipart/form-data
 *     requestBody:
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       "201":
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *                $ref: '#/components/schemas/File'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.post(
  "/files",
  upload.single("file"),
  asyncHandler(async (req, res) => {
    const result = await FileService.uploadFile(req.file);
    res.status(201).json(result);
  })
);

/**
 * @swagger
 * /files/{name}:
 *   get:
 *     summary: Get file by name.
 *     tags: [Files]
 *     parameters:
 *       - in: path
 *         name: name
 *         required: true
 *         schema:
 *           type: string
 *         description: File name
 *     responses:
 *       "200":
 *         description: OK
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/files/:name",
  asyncHandler(async (req, res) => {
    const { download } = req.query;
    await FileService.getFile(res, req.params.name, { download });
  })
);

/**
 * @swagger
 * /files:
 *   get:
 *     summary: Get all files.
 *     tags: [Files]
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *                type: array
 *                items:
 *                  $ref: '#/components/schemas/File'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/files",
  asyncHandler(async (req, res) => {
    const result = await FileService.getFiles();
    res.json(result);
  })
);

/**
 * @swagger
 * /files/{name}:
 *   delete:
 *     summary: Delete file by name.
 *     tags: [Files]
 *     parameters:
 *       - in: path
 *         name: name
 *         required: true
 *         schema:
 *           type: string
 *         description: File name
 *     responses:
 *       "200":
 *         description: No content
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.delete(
  "/files/:name",
  asyncHandler(async (req, res) => {
    const result = await FileService.deleteFile(req.params.name);
    res.json(result);
  })
);

module.exports = router;
