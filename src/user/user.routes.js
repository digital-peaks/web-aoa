const express = require("express");
const asyncHandler = require("express-async-handler");
const UserService = require("./user.service");

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Users
 */

/**
 * @swagger
 * /users:
 *   post:
 *     summary: Create a user
 *     tags: [Users]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *             properties:
 *              name:
 *                type: string
 *              email:
 *                type: string
 *                format: date-time
 *              password:
 *                type: string
 *             example:
 *               {
 *                 "name": "Jane Doe",
 *                 "email": "jane.doe@example.com",
 *                 "password": "cycling-sorority-YUMMY-toaster-42",
 *               }
 *     responses:
 *       "201":
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *                $ref: '#/components/schemas/User'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.post(
  "/users",
  asyncHandler(async (req, res) => {
    const result = await UserService.createUser(req.body);
    res.status(201).json(result);
  })
);

/**
 * @swagger
 * /users:
 *   get:
 *     summary: Get all users
 *     tags: [Users]
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *                type: array
 *                items:
 *                  $ref: '#/components/schemas/User'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/users",
  asyncHandler(async (req, res) => {
    const result = await UserService.getUsers();
    res.json(result);
  })
);

/**
 * @swagger
 * /users/{id}:
 *   delete:
 *     summary: Delete user by id.
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User id
 *     responses:
 *       "200":
 *         description: No content
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.delete(
  "/users/:id",
  asyncHandler(async (req, res) => {
    const result = await UserService.deleteUser(req.params.id);
    res.json(result);
  })
);

module.exports = router;
