#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify this operating system." >&2
  exit 1
fi

. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "This setup script supports Ubuntu. Install nginx, docker.io, docker-compose-v2, git, and openssl manually on other distributions." >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install and start system packages." >&2
  exit 1
fi

sudo apt-get update
sudo apt-get -f install -y

if sudo docker compose version >/dev/null 2>&1; then
  sudo apt-get install -y nginx git openssl
else
  sudo apt-get install -y nginx docker.io docker-compose-v2 git openssl
fi

if [[ "$(ps -p 1 -o comm= | tr -d ' ')" == "systemd" ]]; then
  sudo systemctl enable --now docker nginx
else
  sudo service docker start
  sudo service nginx start
fi

if ! sudo docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is not available after installation." >&2
  exit 1
fi

clone_if_missing() {
  local url="$1"
  local destination="$2"
  if [[ ! -d "$destination/.git" ]]; then
    if [[ -e "$destination" ]]; then
      echo "Refusing to clone over existing non-repository path: $destination" >&2
      exit 1
    fi
    git clone --depth 1 "$url" "$destination"
  fi
}

clone_if_missing \
  "https://github.com/keoKAY/sample-product-reactapp.git" \
  "$BASE_DIR/sample-product-reactapp"
clone_if_missing \
  "https://github.com/keoKAY/spring-sample-product-jpa.git" \
  "$BASE_DIR/spring-sample-product-jpa"

if [[ ! -e "$BASE_DIR/.env" ]]; then
  password="$(openssl rand -hex 32)"
  umask 077
  printf 'POSTGRES_DB=products\nPOSTGRES_USER=products\nPOSTGRES_PASSWORD=%s\n' "$password" > "$BASE_DIR/.env"
  unset password
fi
chmod 600 "$BASE_DIR/.env"

sudo docker compose --env-file "$BASE_DIR/.env" -f "$BASE_DIR/docker-compose.yml" up --build -d

printf '\nFrontend: http://localhost:3000\n'
printf 'Portainer is bound to localhost. To reach it remotely, use an SSH tunnel:\n'
printf '  ssh -L 9443:127.0.0.1:9443 <ssh-user>@<server>\n'
printf 'Then open https://127.0.0.1:9443\n'
