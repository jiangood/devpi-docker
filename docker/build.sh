set -e
docker build -t ghcr.io/jiangood/devpi:latest .
docker push ghcr.io/jiangood/devpi:latest