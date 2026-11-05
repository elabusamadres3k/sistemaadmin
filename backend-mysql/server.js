require('dotenv').config();

const crypto = require('node:crypto');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mysql = require('mysql2/promise');
const rateLimit = require('express-rate-limit');

const requiredEnv = ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'JWT_SECRET'];
for (const name of requiredEnv) {
  if (!process.env[name]) throw new Error(`Missing required environment variable: ${name}`);
}
if (process.env.JWT_SECRET.length < 32) {
  throw new Error('JWT_SECRET must contain at least 32 characters');
}

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'felipe6_local',
  waitForConnections: true,
  connectionLimit: 10,
  charset: 'utf8mb4',
});

const app = express();
const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:5000')
  .split(',')
  .map((origin) => origin.trim());

app.use(helmet());
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Origin not allowed by CORS'));
  },
}));
app.use(express.json({ limit: '1mb' }));

const asyncHandler = (handler) => (req, res, next) =>
  Promise.resolve(handler(req, res, next)).catch(next);
const authLimiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 20 });

function publicUser(row) {
  return {
    id: row.user_id,
    displayName: row.display_name,
    email: row.email,
    username: row.username,
    photoUrl: row.photo_url,
    phoneNumber: row.phone_number,
    bio: row.bio,
    shortDescription: row.short_description,
    title: row.title,
    role: row.role_name,
    createdTime: row.created_time,
  };
}

function issueToken(userId) {
  return jwt.sign({ sub: userId }, process.env.JWT_SECRET, { expiresIn: '12h' });
}

const requireAuth = asyncHandler(async (req, res, next) => {
  const match = /^Bearer\s+(.+)$/i.exec(req.get('authorization') || '');
  if (!match) return res.status(401).json({ error: 'Authentication required' });

  let claims;
  try {
    claims = jwt.verify(match[1], process.env.JWT_SECRET);
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }

  const [rows] = await pool.execute(
    `SELECT u.user_id, u.email, u.display_name, u.username, u.photo_url,
            u.phone_number, u.bio, u.short_description, u.title,
            u.created_time, u.account_status, r.role_name
       FROM users u JOIN roles r ON r.role_id = u.role_id
      WHERE u.user_id = ? LIMIT 1`,
    [claims.sub],
  );
  if (!rows.length || rows[0].account_status !== 'active') {
    return res.status(401).json({ error: 'Account unavailable' });
  }

  req.user = rows[0];
  return next();
});

function requireRole(roleName) {
  return (req, res, next) => {
    if (req.user?.role_name !== roleName) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    return next();
  };
}

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));

app.post('/api/auth/register', authLimiter, asyncHandler(async (req, res) => {
  const { displayName, email, username, password } = req.body || {};
  if (![displayName, email, username, password].every((value) => typeof value === 'string')) {
    return res.status(400).json({ error: 'displayName, email, username and password are required' });
  }
  const cleanEmail = email.trim().toLowerCase();
  const cleanUsername = username.trim();
  if (displayName.trim().length < 1 || displayName.length > 150 ||
      cleanEmail.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail) ||
      !/^[A-Za-z0-9_.-]{3,50}$/.test(cleanUsername) || password.length < 10 || password.length > 128) {
    return res.status(400).json({ error: 'Invalid registration data' });
  }

  const userId = crypto.randomUUID();
  const passwordHash = await bcrypt.hash(password, 12);
  await pool.execute(
    `INSERT INTO users (user_id, display_name, email, username, password_hash, role_id)
     VALUES (?, ?, ?, ?, ?, 1)`,
    [userId, displayName.trim(), cleanEmail, cleanUsername, passwordHash],
  );
  const [rows] = await pool.execute(
    `SELECT u.user_id, u.display_name, u.email, u.username, u.photo_url,
            u.phone_number, u.bio, u.short_description, u.title,
            u.created_time, r.role_name
       FROM users u JOIN roles r ON r.role_id = u.role_id
      WHERE u.user_id = ?`,
    [userId],
  );
  return res.status(201).json({ accessToken: issueToken(userId), user: publicUser(rows[0]) });
}));

app.post('/api/auth/login', authLimiter, asyncHandler(async (req, res) => {
  const { email, password } = req.body || {};
  if (typeof email !== 'string' || typeof password !== 'string') {
    return res.status(400).json({ error: 'email and password are required' });
  }
  const [rows] = await pool.execute(
    `SELECT u.user_id, u.display_name, u.email, u.username, u.photo_url,
            u.phone_number, u.bio, u.short_description, u.title,
            u.created_time, u.password_hash, u.account_status, r.role_name
       FROM users u JOIN roles r ON r.role_id = u.role_id
      WHERE u.email = ? LIMIT 1`,
    [email.trim().toLowerCase()],
  );
  if (!rows.length || rows[0].account_status !== 'active' ||
      !(await bcrypt.compare(password, rows[0].password_hash))) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  await pool.execute('UPDATE users SET last_active_time = CURRENT_TIMESTAMP(3) WHERE user_id = ?', [rows[0].user_id]);
  return res.json({ accessToken: issueToken(rows[0].user_id), user: publicUser(rows[0]) });
}));

app.get('/api/me', requireAuth, (req, res) => res.json({ user: publicUser(req.user) }));

app.get('/api/posts', requireAuth, asyncHandler(async (req, res) => {
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 20, 1), 100);
  const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);
  const [rows] = await pool.execute(
    `SELECT p.post_id AS id, p.post_photo_url AS postPhotoUrl,
            p.post_title AS postTitle, p.post_description AS postDescription,
            p.time_posted AS timePosted, p.num_comments AS numComments,
            p.post_user_id AS postUserId, p.dog_profile_id AS dogProfileId,
            u.display_name AS authorName, u.username AS authorUsername,
            u.photo_url AS authorPhotoUrl
       FROM user_posts p JOIN users u ON u.user_id = p.post_user_id
      WHERE p.content_status = 'published'
        AND u.account_status = 'active'
      ORDER BY p.time_posted DESC LIMIT ? OFFSET ?`,
    [limit, offset],
  );
  return res.json({ items: rows, limit, offset });
}));

app.post('/api/posts', requireAuth, asyncHandler(async (req, res) => {
  const { postPhotoUrl = null, postTitle = null, postDescription = null, dogProfileId = null } = req.body || {};
  const contentFields = [postPhotoUrl, postTitle, postDescription];
  if (contentFields.some((value) => value !== null && typeof value !== 'string') ||
      (dogProfileId !== null && typeof dogProfileId !== 'string')) {
    return res.status(400).json({ error: 'Invalid post data' });
  }
  if (!contentFields.some((value) => typeof value === 'string' && value.trim().length > 0)) {
    return res.status(400).json({ error: 'A title, description or photo URL is required' });
  }
  if ((postTitle?.length ?? 0) > 200 || (postPhotoUrl?.length ?? 0) > 2048 ||
      (postDescription?.length ?? 0) > 60000) {
    return res.status(400).json({ error: 'Post content exceeds the allowed length' });
  }
  if (dogProfileId) {
    const [dogs] = await pool.execute(
      'SELECT dog_id FROM dogs WHERE dog_id = ? AND user_association_id = ?',
      [dogProfileId, req.user.user_id],
    );
    if (!dogs.length) return res.status(400).json({ error: 'Dog profile is not owned by this user' });
  }
  const postId = crypto.randomUUID();
  await pool.execute(
    `INSERT INTO user_posts (post_id, post_photo_url, post_title, post_description,
                             post_user_id, post_owner_id, dog_profile_id)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [postId, postPhotoUrl, postTitle, postDescription, req.user.user_id, req.user.user_id, dogProfileId],
  );
  return res.status(201).json({ id: postId });
}));

app.get('/api/users/:userId', requireAuth, asyncHandler(async (req, res) => {
  const [users] = await pool.execute(
    `SELECT user_id, display_name, username, photo_url, bio, short_description, title
       FROM users WHERE user_id = ? AND account_status = 'active' LIMIT 1`,
    [req.params.userId],
  );
  if (!users.length) return res.status(404).json({ error: 'User not found' });
  const [dogs] = await pool.execute(
    `SELECT dog_id AS id, dog_photo_url AS photoUrl, dog_name AS name,
            dog_type AS type, dog_age AS age, dog_bio AS bio
       FROM dogs WHERE user_association_id = ? ORDER BY dog_name`,
    [req.params.userId],
  );
  return res.json({ user: users[0], dogs });
}));

app.post('/api/chats', requireAuth, asyncHandler(async (req, res) => {
  const email = req.body?.email;
  if (typeof email !== 'string' || !email.includes('@')) {
    return res.status(400).json({ error: 'A valid email is required' });
  }
  const [users] = await pool.execute(
    `SELECT user_id, display_name FROM users
      WHERE email = ? AND account_status = 'active' LIMIT 1`,
    [email.trim().toLowerCase()],
  );
  if (!users.length || users[0].user_id === req.user.user_id) {
    return res.status(404).json({ error: 'Active user not found' });
  }

  const otherUser = users[0];
  const [existing] = await pool.execute(
    `SELECT chat_id AS id FROM chats
      WHERE group_chat_id IS NULL
        AND ((user_a_id = ? AND user_b_id = ?) OR (user_a_id = ? AND user_b_id = ?))
      LIMIT 1`,
    [req.user.user_id, otherUser.user_id, otherUser.user_id, req.user.user_id],
  );
  if (existing.length) {
    return res.json({
      chat: { id: existing[0].id, otherDisplayName: otherUser.display_name },
    });
  }

  const chatId = crypto.randomUUID();
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    await connection.execute(
      'INSERT INTO chats (chat_id, user_a_id, user_b_id) VALUES (?, ?, ?)',
      [chatId, req.user.user_id, otherUser.user_id],
    );
    await connection.execute(
      'INSERT INTO chat_participants (chat_id, user_id) VALUES (?, ?), (?, ?)',
      [chatId, req.user.user_id, chatId, otherUser.user_id],
    );
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  return res.status(201).json({
    chat: { id: chatId, otherDisplayName: otherUser.display_name },
  });
}));

app.get('/api/chats', requireAuth, asyncHandler(async (req, res) => {
  const [rows] = await pool.execute(
    `SELECT c.chat_id AS id, c.last_message AS lastMessage,
            c.last_message_time AS lastMessageTime,
            c.last_message_sent_by AS lastMessageSentBy,
            other_user.user_id AS otherUserId,
            other_user.display_name AS otherDisplayName
       FROM chats c
       JOIN chat_participants mine ON mine.chat_id = c.chat_id
       LEFT JOIN chat_participants other
         ON other.chat_id = c.chat_id
        AND c.group_chat_id IS NULL
        AND other.user_id <> mine.user_id
       LEFT JOIN users other_user ON other_user.user_id = other.user_id
      WHERE mine.user_id = ? ORDER BY c.last_message_time DESC`,
    [req.user.user_id],
  );
  return res.json({ items: rows });
}));

app.get('/api/chats/:chatId/messages', requireAuth, asyncHandler(async (req, res) => {
  const [membership] = await pool.execute(
    'SELECT 1 FROM chat_participants WHERE chat_id = ? AND user_id = ? LIMIT 1',
    [req.params.chatId, req.user.user_id],
  );
  if (!membership.length) return res.status(404).json({ error: 'Chat not found' });
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 100);
  const [items] = await pool.execute(
    `SELECT message_id AS id, user_id AS userId, text, image_url AS imageUrl,
            video_url AS videoUrl, \`timestamp\` AS sentAt
       FROM chat_messages WHERE chat_id = ? ORDER BY \`timestamp\` DESC LIMIT ?`,
    [req.params.chatId, limit],
  );
  return res.json({ items: items.reverse() });
}));

app.post('/api/chats/:chatId/messages', requireAuth, asyncHandler(async (req, res) => {
  const { text = null, imageUrl = null, videoUrl = null } = req.body || {};
  if (![text, imageUrl, videoUrl].some((value) => typeof value === 'string' && value.trim())) {
    return res.status(400).json({ error: 'A text, imageUrl or videoUrl value is required' });
  }
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [membership] = await connection.execute(
      'SELECT 1 FROM chat_participants WHERE chat_id = ? AND user_id = ? FOR UPDATE',
      [req.params.chatId, req.user.user_id],
    );
    if (!membership.length) {
      await connection.rollback();
      return res.status(404).json({ error: 'Chat not found' });
    }
    const messageId = crypto.randomUUID();
    const preview = (text || (imageUrl ? 'Image' : 'Video')).slice(0, 500);
    await connection.execute(
      `INSERT INTO chat_messages (message_id, user_id, chat_id, text, image_url, video_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [messageId, req.user.user_id, req.params.chatId, text, imageUrl, videoUrl],
    );
    await connection.execute(
      `UPDATE chats SET last_message = ?, last_message_time = CURRENT_TIMESTAMP(3),
                        last_message_sent_by = ? WHERE chat_id = ?`,
      [preview, req.user.user_id, req.params.chatId],
    );
    await connection.commit();
    return res.status(201).json({ id: messageId });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}));

app.get('/api/admin/users', requireAuth, requireRole('admin'), asyncHandler(async (req, res) => {
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 100);
  const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);
  const [items] = await pool.execute(
    `SELECT u.user_id AS id, u.display_name AS displayName, u.email,
            u.username, u.account_status AS status, r.role_name AS role,
            u.created_time AS createdTime
       FROM users u JOIN roles r ON r.role_id = u.role_id
      ORDER BY u.created_time DESC LIMIT ? OFFSET ?`,
    [limit, offset],
  );
  return res.json({ items, limit, offset });
}));

app.patch('/api/admin/users/:userId/status', requireAuth, requireRole('admin'), asyncHandler(async (req, res) => {
  const { status } = req.body || {};
  if (!['active', 'suspended'].includes(status)) {
    return res.status(400).json({ error: 'status must be active or suspended' });
  }
  if (req.params.userId === req.user.user_id && status === 'suspended') {
    return res.status(400).json({ error: 'Administrators cannot suspend their own account' });
  }
  const [result] = await pool.execute(
    'UPDATE users SET account_status = ? WHERE user_id = ?',
    [status, req.params.userId],
  );
  if (!result.affectedRows) return res.status(404).json({ error: 'User not found' });
  return res.json({ id: req.params.userId, status });
}));

app.get('/api/admin/posts', requireAuth, requireRole('admin'), asyncHandler(async (req, res) => {
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 100);
  const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);
  const [items] = await pool.execute(
    `SELECT p.post_id AS id, p.post_title AS title,
            p.post_description AS description, p.content_status AS status,
            p.time_posted AS timePosted, u.username AS authorUsername
       FROM user_posts p JOIN users u ON u.user_id = p.post_user_id
      ORDER BY p.time_posted DESC LIMIT ? OFFSET ?`,
    [limit, offset],
  );
  return res.json({ items, limit, offset });
}));

app.get('/api/admin/comments', requireAuth, requireRole('admin'), asyncHandler(async (req, res) => {
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 50, 1), 100);
  const offset = Math.max(Number.parseInt(req.query.offset, 10) || 0, 0);
  const [items] = await pool.execute(
    `SELECT c.comment_id AS id, c.comment, c.content_status AS status,
            c.time_posted AS timePosted, c.post_id AS postId,
            u.username AS authorUsername
       FROM post_comments c JOIN users u ON u.user_id = c.user_id
      ORDER BY c.time_posted DESC LIMIT ? OFFSET ?`,
    [limit, offset],
  );
  return res.json({ items, limit, offset });
}));

app.delete('/api/admin/posts/:postId', requireAuth, requireRole('admin'), asyncHandler(async (req, res) => {
  const [result] = await pool.execute('DELETE FROM user_posts WHERE post_id = ?', [req.params.postId]);
  if (!result.affectedRows) return res.status(404).json({ error: 'Post not found' });
  return res.status(204).end();
}));

app.delete('/api/admin/comments/:commentId', requireAuth, requireRole('admin'), asyncHandler(async (req, res) => {
  const [result] = await pool.execute('DELETE FROM post_comments WHERE comment_id = ?', [req.params.commentId]);
  if (!result.affectedRows) return res.status(404).json({ error: 'Comment not found' });
  return res.status(204).end();
}));

app.use((req, res) => res.status(404).json({ error: 'Route not found' }));
app.use((error, req, res, next) => {
  if (error.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ error: 'Email or username already exists' });
  }
  if (error.message === 'Origin not allowed by CORS') {
    return res.status(403).json({ error: error.message });
  }
  console.error(error);
  return res.status(500).json({ error: 'Internal server error' });
});

const port = Number(process.env.PORT || 3000);
const host = process.env.HOST || '127.0.0.1';
app.listen(port, host, () => console.log(`REST API listening on http://${host}:${port}`));
