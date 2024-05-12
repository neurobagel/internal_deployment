# Neurobagel internal deployments

This repository contains the deployment configurations for the internal services of Neurobagel.

## Services

- NGINX: self-configuring reverse proxy
- Portainer: Docker container management
- Letsencryp: SSL certificate management

These services should be started before any other service.

## Usage

```bash
docker-compose up -d
```
