# Server Hosting Guide for Sus

This guide provides clear, step-by-step instructions on how to host your own **Sus** game server in production. Whether you are an experienced developer or a non-technical beginner hosting your first app, this guide explains every click and command.

---

## Quick Navigation

- [⭐ Top Recommendation: Render (Free & Fast)](#-top-recommendation-render-free--fast)
  - [Method 1: 1-Click Blueprint (Easiest)](#method-1-1-click-blueprint-easiest)
  - [Method 2: Manual Web Service Setup](#method-2-manual-web-service-setup)
- [Alternative 1: Railway](#alternative-1-railway)
- [Alternative 2: Self-Hosted VPS (Docker / Ubuntu)](#alternative-2-self-hosted-vps-docker--ubuntu)
- [Testing Your Deployed Server](#testing-your-deployed-server)
- [Connecting the Flutter App to Your Server](#connecting-the-flutter-app-to-your-server)
- [Troubleshooting & FAQs](#troubleshooting--faqs)

---

## ⭐ Top Recommendation: Render (Free & Fast)

[Render](https://render.com) is our **#1 recommended platform** to host the Sus server because:
- **Free Tier**: You can run the server at zero cost.
- **WebSocket & Socket.IO Support**: Full persistent HTTP upgrade and WebSocket connections without extra configuration.
- **Automatic HTTPS/SSL**: Render provides a free SSL certificate (`https://your-service.onrender.com`).
- **Zero Server Management**: No Linux terminal management or firewall configuration required.
- **Git Continuous Deployment**: Pushing updates to GitHub automatically builds and redeploys the server.

### Method 1: 1-Click Blueprint (Easiest)

Because this repository includes a [`render.yaml`](../render.yaml) blueprint, Render can automatically detect and configure the server in one click:

1. Create a free account at [render.com](https://render.com) or log in with GitHub.
2. In your Render Dashboard, click **New +** in the top navigation bar and select **Blueprint**.
3. Connect your GitHub repository (`Sus`).
4. Render will read `render.yaml` and display the `sus-server` service configuration.
5. Click **Apply**.
6. Wait 1–2 minutes for the build to finish. Once done, Render gives you a live public URL (e.g. `https://sus-server-xyz.onrender.com`).

---

### Method 2: Manual Web Service Setup

If you prefer to configure the service manually on Render:

1. **Sign in to Render**: Go to [dashboard.render.com](https://dashboard.render.com).
2. **Create Web Service**:
   - Click the **New +** button in the top right.
   - Choose **Web Service**.
3. **Connect Repository**:
   - Choose **Build and deploy from a Git repository**.
   - Select your `Sus` repository.
4. **Configure Settings**:
   Fill in the form with these exact settings:
   - **Name**: `sus-game-server` (or any name you like)
   - **Region**: Choose the region closest to you (e.g., Frankfurt, Oregon, Singapore)
   - **Branch**: `main` (or your feature branch)
   - **Root Directory**: `server`
   - **Runtime**: `Node`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`
   - **Instance Type**: Select **Free**
5. **Environment Variables**:
   Scroll down to the **Environment Variables** section and click **Add Environment Variable**:
   | Key | Value | Description |
   | :--- | :--- | :--- |
   | `NODE_ENV` | `production` | Enables optimized production runtime |
   | `CORS_ORIGIN` | `*` | Allows client apps from any device to connect |
6. **Health Check Path** (Optional but recommended):
   - Under Advanced Settings, set **Health Check Path** to `/health`.
7. **Deploy**:
   - Click **Create Web Service**.
   - Render will build the TypeScript server and start it.
   - When the logs display `Sus server listening`, your server is live!

> [!NOTE]
> On Render's Free tier, services spin down after 15 minutes of inactivity. When a player opens the app, the first connection may take 20–30 seconds to wake the server up. For 24/7 instant party play with friends, you can upgrade to Render's Starter plan ($7/mo) or use a free cron ping like UptimeRobot on `https://your-service.onrender.com/health`.

---

## Alternative 1: Railway

[Railway](https://railway.app) is another modern hosting provider:

1. Go to [railway.app](https://railway.app) and sign in with GitHub.
2. Click **New Project** > **Deploy from GitHub repo**.
3. Select the `Sus` repository.
4. Click on the created service card, go to **Settings**:
   - Set **Root Directory** to `/server`.
5. In the **Variables** tab, add:
   - `NODE_ENV`: `production`
   - `PORT`: `3000`
   - `CORS_ORIGIN`: `*`
6. Under **Networking**, click **Generate Domain** to get a public URL like `https://sus-production.up.railway.app`.

---

## Alternative 2: Self-Hosted VPS (Docker / Ubuntu)

If you own an Ubuntu/Debian Virtual Private Server (DigitalOcean, Hetzner, AWS, Linode):

### Using Docker Compose

1. **Install Docker and Docker Compose**:
   ```bash
   sudo apt update && sudo apt install -y docker.io docker-compose git
   ```
2. **Clone the repository**:
   ```bash
   git clone https://github.com/akashrai-dev-spec/Sus.git
   cd Sus
   ```
3. **Start the server with Docker Compose**:
   ```bash
   docker-compose up -d --build
   ```
   The server will start in the background on port `3000`.

### Nginx Reverse Proxy with SSL (HTTPS / WSS)

To connect mobile clients securely, set up Nginx with SSL:

1. **Install Nginx and Certbot**:
   ```bash
   sudo apt install -y nginx certbot python3-certbot-nginx
   ```
2. **Configure Nginx** at `/etc/nginx/sites-available/sus`:
   ```nginx
   server {
       server_name sus.yourdomain.com;

       location / {
           proxy_pass http://localhost:3000;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection "upgrade";
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```
3. **Enable and Obtain SSL**:
   ```bash
   sudo ln -s /etc/nginx/sites-available/sus /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl reload nginx
   sudo certbot --nginx -d sus.yourdomain.com
   ```

---

## Testing Your Deployed Server

Once deployed, open your web browser or terminal and test the health endpoint:

```bash
curl https://your-server-name.onrender.com/health
```

Expected response:
```json
{"status":"ok","version":"1.0.0"}
```

If you see this response, your server is functioning and ready to host multiplayer rooms!

---

## Connecting the Flutter App to Your Server

To connect the Flutter client app to your deployed server:

### Option A: Running from Terminal / Command Line
When running the app on Linux, Android, or iOS:
```bash
cd app
flutter run -d linux --dart-define=SERVER_URL=https://your-server-name.onrender.com
```

### Option B: Building a Release Android APK
When building the APK for yourself and friends:
```bash
cd app
flutter build apk --release --dart-define=SERVER_URL=https://your-server-name.onrender.com
```
(See [Android APK Build Guide](BUILD_APK.md) for full instructions).

---

## Troubleshooting & FAQs

### 1. The app says "Connecting..." and fails to join rooms
- Ensure your server URL begins with `https://` (or `http://` for local network testing).
- Check that the health check URL (`https://your-server.onrender.com/health`) responds in your browser.
- If using Render Free tier, wait 30 seconds for the cold start to complete.

### 2. Sockets disconnect after a short period
- Check that your proxy allows WebSocket upgrade headers (`Upgrade $http_upgrade` and `Connection "upgrade"`). On Render and Railway, this is handled automatically.

### 3. How many players can a free instance support?
- A standard free instance (512MB RAM) easily handles dozens of concurrent 12-player rooms because Socket.IO in Node.js has very lightweight event loop overhead.
