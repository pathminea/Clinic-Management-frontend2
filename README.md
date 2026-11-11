# Product full-stack deployment

This deployment builds the linked React and Spring Boot repositories and runs them with PostgreSQL and Portainer. Nginx serves the React build on port `3000` and proxies `/api/...` requests to Spring Boot. The database and API are not published on host ports.

## Install and start on Ubuntu or Ubuntu on WSL2

From this directory, run:

```bash
bash setup.sh
```

The script repairs pending package configuration, installs `nginx`, Git, and OpenSSL, and installs Ubuntu's Docker Engine and Compose v2 only if a working `docker compose` command is not already available. It then clones the two application repositories if they are not already present, creates a private `.env` with a random database password, and starts the Compose stack.

Open the frontend at [http://localhost:3000](http://localhost:3000). WSL2 normally forwards localhost ports to Windows. If Docker is not running on WSL2, enable systemd for the distro or start it with `sudo service docker start`.

The script uses `sudo docker compose`; alternatively, you can add your user to the `docker` group and start a new login session. Membership in that group grants root-equivalent Docker access.

## Remote server access

For a remote VM, allow inbound TCP port `3000` in its firewall/security group (preferably restricted to your client IP), then browse to `http://<server-ip>:3000`. Do not publish ports `5432` or `8080`.

Portainer listens only on the server's loopback interface to avoid exposing its administrative UI publicly. Connect with:

```bash
ssh -L 9443:127.0.0.1:9443 <ssh-user>@<server-ip>
```

Then open `https://127.0.0.1:9443` and complete Portainer's first-run admin setup. Do not open port `9443` to the public internet.

## Operations

```bash
sudo docker compose ps
sudo docker compose logs -f
sudo docker compose pull
sudo docker compose up --build -d
sudo docker compose down
```

`docker compose down` preserves the named PostgreSQL and Portainer volumes. To change the database password later, update `.env` and coordinate the database credential change; changing the environment variable alone does not update an existing PostgreSQL user's password.

The app repositories are cloned into this directory. Update them intentionally with `git -C sample-product-reactapp pull` and `git -C spring-sample-product-jpa pull`, then rebuild using `sudo docker compose up --build -d`.
