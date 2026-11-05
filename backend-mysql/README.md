# MySQL REST backend

The Flutter entry point now starts a MySQL-backed experience by default. This folder contains its MySQL schema and Node.js REST API; `lib/mysql_app.dart` provides registration/login, feed, private chats, profile, and an admin user panel. The original Firebase/FlutterFlow screens remain in the repository as a fallback but are not the default app experience.

## Requirements

- MySQL 8.0.16 or newer
- Node.js 20 or newer
- A Flutter device/browser that can reach the computer running this API

## Start MySQL and create the schema

From the repository root, import the schema using a local MySQL account with database creation privileges:

```powershell
mysql -u root -p -e "source backend-mysql/schema.sql"
```

For anything beyond local development, create a dedicated MySQL account and grant it access only to `felipe6_local`; do not run the API as MySQL root.

For local development, create a database account matching `.env.example` (use a different password from your MySQL root account):

```sql
CREATE USER IF NOT EXISTS 'felipe6_app'@'127.0.0.1' IDENTIFIED BY 'choose-a-local-password';
GRANT SELECT, INSERT, UPDATE, DELETE ON felipe6_local.* TO 'felipe6_app'@'127.0.0.1';
FLUSH PRIVILEGES;
```

## Configure and run the API

```powershell
cd backend-mysql
Copy-Item .env.example .env
```

Edit `.env` with the MySQL account above and a randomly generated `JWT_SECRET` of at least 32 characters. Then run:

```powershell
npm install
npm start
```

Check the API at `http://localhost:3000/api/health`.
The API and MySQL are bound to loopback by default; neither service is exposed to the LAN or cloud.

## Run Flutter against the API

`lib/backend/api_requests/mysql_api_client.dart` reads `API_BASE_URL` at build time. For Flutter Web on port 5000:

```powershell
flutter run -d chrome --web-port=5000 --dart-define=USE_MYSQL_BACKEND=true --dart-define=API_BASE_URL=http://localhost:3000/api
```

For the Android Studio emulator, use its host-machine alias:

```powershell
flutter run -d emulator-5554 --dart-define=USE_MYSQL_BACKEND=true --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Android debug builds allow cleartext HTTP for this local development connection only. The Android Emulator reaches the computer through `10.0.2.2`; the default setup does not expose the API to a physical phone or the LAN. Use HTTPS and explicit network configuration before any non-local deployment.

To temporarily launch the original Firebase app instead, run with `--dart-define=USE_MYSQL_BACKEND=false`.

## API routes included

- `POST /api/auth/register`, `POST /api/auth/login`, `GET /api/me`
- `GET /api/posts`, `POST /api/posts`
- `GET /api/users/:userId`
- `GET /api/chats`, `POST /api/chats`, `GET /api/chats/:chatId/messages`, `POST /api/chats/:chatId/messages`
- `GET /api/admin/users`, `PATCH /api/admin/users/:userId/status`
- `GET /api/admin/posts`, `GET /api/admin/comments`
- `DELETE /api/admin/posts/:postId`, `DELETE /api/admin/comments/:commentId`

Protected endpoints require `Authorization: Bearer <accessToken>`. Admin endpoints load the current role from MySQL on every request. Public registration always assigns the `user` role.

## Promote the first administrator

Register that account through the API first, then promote it using a trusted local MySQL session:

```sql
UPDATE users
SET role_id = (SELECT role_id FROM roles WHERE role_name = 'admin')
WHERE email = 'admin@example.com';
```

Never expose an endpoint that lets a client choose its own role.

## Migration status and important limits

The Dart client keeps the JWT in memory, so users sign in again after restarting the app. Existing Firebase accounts are not imported; create new MySQL accounts because Firebase Auth password hashes cannot be exported for this flow. Stories, comments, follows, dog-profile editing, and media uploads still need API/UI migration. Media fields currently accept URLs; a separate upload/storage service is required for photos and videos.
