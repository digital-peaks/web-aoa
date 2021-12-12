const fs = require("fs");
const path = require("path");
const File = require("./file.model");
const {
  InternalServerErrorException,
  NotFoundException,
  BadRequestException,
} = require("../utils/exceptions");
const logger = require("../utils/logger");

const MAX_UPLOAD_SIZE_MB =
  Number.parseInt(process.env.FILES_MAX_UPLOAD_SIZE_MB, 10) || 10;

const ALLOWED_MIME_TYPES = [
  // Images:
  "image/jpeg",
  "image/png",
  "image/tiff",
  // GeoPackage (*.gpkg):
  "application/octet-stream",
  // GeoJSON (*.geojson, *.json):
  "application/geo+json",
  "application/json",
];

const FILES_FOLDER = path.join(__dirname, "/../../files");

/**
 * Get extension from filename.
 * "my_file.jpeg" -> "jpeg"
 * @param {string} filename
 * @returns
 */
const buildFilenameExtension = (filename) => {
  const ext = filename.split(".").pop();
  return ext ? ext.toLowerCase() : "";
};

/**
 * Remove filename extension.
 * "my_file.jpeg" -> "my_file"
 * @param {string} filename
 * @returns
 */
const removeFilenameExtension = (filename) => filename.replace(/\.[^/.]+$/, "");

/**
 * Build filename based on the id and the file extension.
 * @param {*} file
 * @returns
 */
const buildFilename = (file) => `${file.id}.${file.extension}`;

/**
 * Upload file.
 */
const uploadFile = async (upload) => {
  const { mimetype: mime_type, originalname: original_name, size } = upload;

  logger.info(`File size: ${size}`);

  if (size > 1024 * 1024 * MAX_UPLOAD_SIZE_MB) {
    throw new BadRequestException(
      `Maximum upload file size: ${MAX_UPLOAD_SIZE_MB} MB`
    );
  }

  logger.info(`MIME-Type: ${mime_type}`);

  if (!ALLOWED_MIME_TYPES.includes(mime_type)) {
    throw new BadRequestException(
      `MIME-Type not allowed. Allowed: ${ALLOWED_MIME_TYPES.join(", ")}`
    );
  }

  const extension = buildFilenameExtension(original_name);

  const fileRaw = await File.create({
    extension,
    original_name,
    mime_type,
    size,
  });

  const file = fileRaw.toJSON();

  file.name = buildFilename(file);

  logger.info(`Saving file: ${file.name}`);

  try {
    // eslint-disable-next-line security/detect-non-literal-fs-filename
    await fs.promises.writeFile(
      path.join(FILES_FOLDER, file.name),
      upload.buffer
    );
  } catch (err) {
    logger.error(err);
    await File.deleteOne({ _id: file.id });
    const serverErr = InternalServerErrorException("Unable to save file");
    serverErr.stack = err.stack;
    throw serverErr;
  }

  logger.info(`Saved file: ${file.name}`);

  return file;
};

/**
 * Get file by name.
 * @param {string} name
 * @returns
 */
const getFile = async (res, name, options) => {
  const { download } = options;

  const fileId = removeFilenameExtension(name);
  const fileData = await File.findOne({ _id: fileId, user_id: 0 });

  if (!fileData) {
    throw new NotFoundException("Unable to find file");
  }

  const sendFileOptions = {
    root: FILES_FOLDER,
    dotfiles: "deny",
  };

  if (download === "true") {
    sendFileOptions.headers = {
      "Content-disposition": `attachment;filename=${fileData.original_name}`,
    };
  }

  const filename = buildFilename(fileData);

  res.sendFile(filename, sendFileOptions);
};

/**
 * Get all files.
 * @returns
 */
const getFiles = async () => {
  const files = await File.find({ user_id: 0 }).sort({ created: "desc" });

  const filesData = files.map((file) => ({
    ...file.toJSON(),
    name: buildFilename(file),
  }));

  return filesData;
};

/**
 * Delete job by name.
 * @param {string} name
 * @returns
 */
const deleteFile = async (name) => {
  // Search file by id only:
  const fileId = removeFilenameExtension(name);
  const fileData = await File.findOneAndDelete({ _id: fileId, user_id: 0 });

  if (!fileData) {
    throw new NotFoundException("Unable to find file");
  }

  // Delete from storage:
  const filename = buildFilename(fileData);
  // eslint-disable-next-line security/detect-non-literal-fs-filename
  await fs.promises.unlink(path.join(FILES_FOLDER, filename));

  logger.info(`Deleted file: ${filename}`);

  return { deletedCount: 1 };
};

module.exports = {
  uploadFile,
  getFile,
  getFiles,
  deleteFile,
};
