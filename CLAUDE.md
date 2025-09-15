# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible automation project for deploying Evolution API v2.3.2 (WhatsApp integration platform) with Docker Compose, PostgreSQL 16, Redis 7, Nginx, and SSL certificates. The deployment targets Ubuntu/Debian servers and handles complete setup including security, automated backups, and monitoring. Evolution API runs alongside n8n on the same server for workflow automation integration.

## Key Commands

### Running Deployments

```bash
# Quick installation with interactive menu
./run-installation.sh

# Deploy Evolution API directly
ansible-playbook -i inventory/hosts.yml deploy-evolution.yml --ask-vault-pass

# Update only Nginx/SSL configuration
ansible-playbook -i inventory/hosts.yml update-nginx-ssl.yml --ask-vault-pass

# Uninstall Evolution API
ansible-playbook -i inventory/hosts.yml uninstall-evolution.yml --ask-vault-pass
```

### Vault Management

```bash
# Encrypt vault file
ansible-vault encrypt group_vars/all/vault.yml

# Edit encrypted vault
ansible-vault edit group_vars/all/vault.yml

# Decrypt vault (temporarily)
ansible-vault decrypt group_vars/all/vault.yml
```

### Testing and Validation

```bash
# Test connectivity to server
ansible -i inventory/hosts.yml all -m ping --ask-vault-pass

# Syntax check playbooks
ansible-playbook deploy-evolution.yml --syntax-check

# Dry run (check mode)
ansible-playbook -i inventory/hosts.yml deploy-evolution.yml --check --ask-vault-pass
```

## Architecture and Key Design Decisions

### Playbook Structure

1. **deploy-evolution.yml**: Main deployment playbook that assumes Docker is already installed. Handles Evolution API setup with PostgreSQL, Redis, Nginx, and SSL configuration.

2. **update-nginx-ssl.yml**: Standalone playbook for adding/updating Nginx and SSL configuration to existing Evolution installations.

3. **uninstall-evolution.yml**: Complete removal playbook with final backup creation.

### Critical Implementation Details

**Port Configuration**: Evolution API uses port 8080 (avoiding conflicts with existing services). Redis mapped to 6381 to avoid conflict with nextcloud-redis on 6379.

**Container Names**: Prefixed with `evolution_` to avoid conflicts:
- evolution_api
- evolution_postgres
- evolution_redis

**Volume Binding**: Uses bind mounts for easier backup management:
- Evolution data: `/root/evolution/volumes/evolution_data`
- PostgreSQL: `/root/evolution/volumes/postgres_data`
- Redis: `/root/evolution/volumes/redis_data`

**API Authentication**: Uses API Key authentication stored in vault. The key must be passed in the `apikey` header for all API requests.

### Server Configuration

Target server configuration (inventory/hosts.yml):
- Default path: `/root/evolution`
- Domain: `evolution.wbdigitalsolutions.com`
- Evolution API port: 8080
- PostgreSQL 16 with dedicated database
- Redis 7 on port 6381
- Nginx as reverse proxy with SSL

### Integration with n8n

Evolution API is designed to work alongside n8n (running on port 5678):
- Internal Docker network communication: `http://evolution_api:8080`
- n8n can send webhooks to Evolution for WhatsApp automation
- Evolution can trigger n8n workflows via webhooks

### Template Processing

All configuration files are generated from Jinja2 templates in `templates/`:
- `docker-compose.yml.j2`: Docker Compose with 3 services
- `env.j2`: Comprehensive environment variables for Evolution API
- `backup-evolution.sh.j2`: Daily backup script with 30-day retention
- `monitor-evolution.sh.j2`: Health check every 5 minutes via cron
- `nginx-evolution.conf.j2`: Nginx reverse proxy with WebSocket support
- `init-db.sql.j2`: PostgreSQL initialization
- `installation-info.txt.j2`: Complete installation documentation

## Common Issues and Solutions

### Port Conflicts
Check for conflicts before deployment:
```bash
netstat -tlnp | grep -E "8080|6381"
```

### DNS Configuration for SSL
Certbot requires proper DNS A record pointing to server IP before SSL certificate generation:
```bash
nslookup evolution.wbdigitalsolutions.com
dig +short evolution.wbdigitalsolutions.com
```

### Container Health Checks
Evolution API includes health checks at `/healthcheck`. Monitor script automatically restarts if 3 consecutive failures.

## Deployment Workflow

1. Vault contains encrypted credentials
2. Playbook creates directory structure at `/root/evolution`
3. Deploys PostgreSQL 16 and waits for health
4. Deploys Redis 7 with authentication
5. Starts Evolution API v2.3.2
6. Configures Nginx reverse proxy
7. Obtains Let's Encrypt SSL certificate
8. Sets up automated backups and monitoring

## Development and Testing

### Local Testing
```bash
# Test all playbook syntax
for playbook in *.yml; do ansible-playbook $playbook --syntax-check; done

# Validate inventory
ansible-inventory -i inventory/hosts.yml --list

# Check vault encryption
file group_vars/all/vault.yml | grep -q "data" && echo "encrypted" || echo "plaintext"
```

### Python Dependencies
```bash
pip install -r requirements.txt
```

## Important File References

### Core Playbooks
- `deploy-evolution.yml`: Main deployment
- `update-nginx-ssl.yml`: SSL/Nginx updates
- `uninstall-evolution.yml`: Complete removal

### Configuration Files
- `inventory/hosts.yml`: Server inventory and variables
- `group_vars/all/vault.yml`: Encrypted credentials
- `ansible.cfg`: Ansible settings
- `requirements.txt`: Python dependencies

### Helper Scripts
- `run-installation.sh`: Interactive installation wizard

## Repository Maintenance

When updating playbooks:
- Test syntax before committing: `ansible-playbook <playbook>.yml --syntax-check`
- Maintain compatibility with existing `/root/evolution` installation path
- Keep container names prefixed with `evolution_`
- Ensure port mappings don't conflict with existing services
- Update version number in docker-compose.yml.j2 when upgrading Evolution API