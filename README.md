# Node Docker Demo — Docker Compose & Docker Swarm (Nginx + Certbot)

A minimal Node.js API packaged for Docker. Includes:
- **Compose** for local dev/testing.
- **Swarm** stack with **Nginx** reverse proxy and **Certbot** for HTTPS on `swam.kamaljits.xyz`.
- Security hardening (non-root user, read-only FS, dropped capabilities, no-new-privileges).

> **Note:** I’m assuming you want a branch named `swarm`. If you actually want `swam`, just replace the branch name in the commands below.

---

## Project Structure

```
node-docker-demo/
├─ app.js                 # Node.js (ESM) app
├─ package.json           # "type": "module"; express dependency
├─ .dockerignore
├─ Dockerfile             # Multi-stage, healthcheck, non-root runtime
├─ docker-compose.yml     # Local run (compose)
├─ docker-stack.yml       # Swarm stack (web+nginx+certbot)
└─ nginx.conf             # Nginx vhost for swam.kamaljits.xyz
```

---

## Quick Start (Compose)

```bash
# Build & run locally
docker compose up --build -d
curl http://localhost:3000
# Stop
docker compose down
```

---

## Docker Swarm Deployment

### 1) Prereqs
- DNS `A` record for **swam.kamaljits.xyz** → your Swarm manager’s public IP.
- Swarm initialized:
  ```bash
  docker swarm init
  ```

### 2) Build & (optionally) Push Image
Single-node demo (local image is fine):
```bash
docker build -t node-docker-demo:1.0.0 .
```

Multi-node cluster (push to a registry and update `image:` in `docker-stack.yml`):
```bash
# Docker Hub example
docker tag node-docker-demo:1.0.0 <dockerhub-user>/node-docker-demo:1.0.0
docker push <dockerhub-user>/node-docker-demo:1.0.0
```

### 3) (Optional) Create a Secret
The app reads and returns the secret content on `/` if present:
```bash
printf "Hello from Swarm secret! 🐳" | docker secret create app_message -
```

### 4) Deploy the Stack
```bash
docker stack deploy -c docker-stack.yml nodeapp
```

### 5) Issue TLS Certificate (one-time)
```bash
docker service scale nodeapp_certbot_init=1
docker service logs -f nodeapp_certbot_init
# After success:
docker service scale nodeapp_certbot_init=0
```

### 6) Verify & Renewals
```bash
curl -I http://swam.kamaljits.xyz
curl -I https://swam.kamaljits.xyz
```
- `certbot_renew` runs every 12h. Reload Nginx to pick up renewed certs:
```bash
docker service update --force nodeapp_nginx
```

---

## Security Notes
- Runtime user is non-root (`USER node`).
- `read_only` filesystem + `tmpfs` for `/tmp` and `/run` in Compose/Swarm.
- `cap_drop: ALL` and `no-new-privileges` in Compose/Swarm.
- Nginx serves only as reverse proxy with tight TLS config + security headers.

---

## Push to a `swarm` Branch

> Replace placeholders like `<your-username>` and `<your-repo>`.

### First Push
```bash
# From the directory that contains node-docker-demo/
cd node-docker-demo

# Initialize repo (skip if your repo is already initialized)
git init

# Create and switch to 'swarm' branch
git checkout -b swarm

# Add files and commit
git add .
git commit -m "Add Node app with Compose & Swarm (Nginx+Certbot)"

# Add remote
git remote add origin https://github.com/<your-username>/<your-repo>.git

# Push 'swarm' branch
git push -u origin swarm
```

### If Repo Already Exists
```bash
# Start from repo root
git fetch origin
git checkout -b swarm
git add node-docker-demo/*
git commit -m "Add Node app stack for Docker Swarm"
git push -u origin swarm
```

### Create Pull Request
Open your GitHub repo and create a PR from `swarm` → `main` (or keep `swarm` as a long-lived env branch).

---

## Useful Commands

```bash
# Swarm status
docker stack services nodeapp
docker service ps nodeapp_web

# Force zero-downtime update after changing image tag
docker stack deploy -c docker-stack.yml nodeapp

# Remove stack
docker stack rm nodeapp
```

---

## Troubleshooting

- **`npm ci` requires package-lock.json** → the Dockerfile falls back to `npm install` if no lockfile.
- **No HTTPS** → ensure DNS points to the manager, run `certbot_init`, check volume mounts on the node running `nginx`.
- **Multi-node certs** → use a shared/replicated volume for `/etc/letsencrypt` or pin Nginx to a single edge node.
