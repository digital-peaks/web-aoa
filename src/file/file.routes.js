const express = require("express");
const asyncHandler = require("express-async-handler");
const multer = require("multer");
const FileService = require("./file.service");

const upload = multer();

const router = express.Router();

router.post(
  "/files",
  upload.single("file"),
  asyncHandler(async (req, res) => {
    const result = await FileService.uploadFile(req.file);
    res.json(result);
  })
);

router.get(
  "/files/:name",
  asyncHandler(async (req, res) => {
    const { download } = req.query;
    await FileService.getFile(res, req.params.name, { download });
  })
);

router.get(
  "/files",
  asyncHandler(async (req, res) => {
    const result = await FileService.getFiles();
    res.json(result);
  })
);

router.delete(
  "/files/:name",
  asyncHandler(async (req, res) => {
    const result = await FileService.deleteFile(req.params.name);
    res.json(result);
  })
);

module.exports = router;
