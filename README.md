# Evolution API - Ansible Deployment

Automação completa para instalação do Evolution API (WhatsApp) com Docker Compose usando Ansible.

## 🚀 Sobre o Evolution API

Evolution API v2.3.2 é uma solução open-source para integração com WhatsApp, oferecendo:
- API RESTful completa para WhatsApp
- Suporte a múltiplas instâncias
- WebSocket para eventos em tempo real
- Integração com n8n, Typebot, Chatwoot, e mais
- Dashboard de gerenciamento

## 📋 Pré-requisitos

### Na Máquina Local
- Ansible 2.9+ instalado
- Python 3.x
- SSH configurado para acesso ao servidor

### No Servidor Remoto
- Ubuntu 20.04+ ou Debian 11+
- Docker e Docker Compose instalados
- Mínimo 2GB RAM
- 10GB espaço em disco
- Portas 8080 e 6381 disponíveis

## 🛠️ Instalação Rápida

### 1. Clonar o Repositório
```bash
git clone <seu-repositorio>
cd ansible-evolution
```

### 2. Instalar Dependências Python
```bash
pip install -r requirements.txt
```

### 3. Configurar Inventário
Edite `inventory/hosts.yml`:
```yaml
all:
  hosts:
    evolution_server:
      ansible_host: 45.90.123.190  # Seu IP
      ansible_user: root
      evolution_domain: evolution.wbdigitalsolutions.com  # Seu domínio
```

### 4. Configurar Credenciais
Edite `group_vars/all/vault.yml` com suas senhas seguras.

### 5. Criptografar Vault
```bash
ansible-vault encrypt group_vars/all/vault.yml
```

### 6. Executar Instalação
```bash
./run-installation.sh
```

Ou manualmente:
```bash
ansible-playbook -i inventory/hosts.yml deploy-evolution.yml --ask-vault-pass
```

## 🔧 Configurações Disponíveis

### Variáveis Principais (inventory/hosts.yml)

| Variável | Descrição | Padrão |
|----------|-----------|---------|
| `evolution_domain` | Domínio para Evolution API | `evolution.wbdigitalsolutions.com` |
| `evolution_port` | Porta do Evolution API | `8080` |
| `postgres_version` | Versão PostgreSQL | `16` |
| `redis_port` | Porta Redis | `6381` |
| `enable_ssl` | Ativar SSL/HTTPS | `true` |
| `enable_nginx` | Configurar Nginx | `true` |
| `enable_backup` | Backups automáticos | `true` |
| `enable_monitoring` | Monitoramento | `true` |

### Integrações Opcionais

- `enable_webhook`: Webhooks globais
- `enable_websocket`: WebSocket para eventos
- `enable_rabbitmq`: Fila RabbitMQ
- `enable_typebot`: Integração Typebot
- `enable_chatwoot`: Integração Chatwoot
- `enable_openai`: Integração OpenAI
- `enable_s3`: Storage S3/MinIO

## 📁 Estrutura no Servidor

```
/root/evolution/
├── docker-compose.yml
├── .env
├── volumes/
│   ├── evolution_data/     # Dados das instâncias
│   ├── postgres_data/      # Banco PostgreSQL
│   └── redis_data/         # Cache Redis
├── backups/                # Backups automáticos
├── logs/                   # Logs da aplicação
├── config/                 # Configurações
├── backup-evolution.sh     # Script de backup
├── monitor-evolution.sh    # Script de monitoramento
└── INSTALLATION_INFO.txt   # Informações da instalação
```

## 🔐 Segurança

### API Key
A autenticação é feita via API Key no header:
```bash
curl -H "apikey: YOUR_API_KEY" https://evolution.seu-dominio.com/instance/fetchInstances
```

### SSL/HTTPS
- Certificados Let's Encrypt configurados automaticamente
- Renovação automática mensal
- Redirecionamento HTTP → HTTPS

## 💾 Backups

### Automático
- Executado diariamente às 3:00 AM
- Retenção de 30 dias
- Inclui: banco de dados, arquivos, configurações

### Manual
```bash
ssh root@servidor '/root/evolution/backup-evolution.sh'
```

### Restauração
```bash
# 1. Parar serviços
docker compose -f /root/evolution/docker-compose.yml down

# 2. Restaurar banco
gunzip -c /root/evolution/backups/evolution_db_TIMESTAMP.sql.gz | \
  docker exec -i evolution_postgres psql -U evolution evolution_db

# 3. Restaurar dados
tar -xzf /root/evolution/backups/evolution_data_TIMESTAMP.tar.gz \
  -C /root/evolution/volumes/evolution_data/

# 4. Reiniciar
docker compose -f /root/evolution/docker-compose.yml up -d
```

## 🔄 Integração com n8n

O n8n está rodando no mesmo servidor. Para integrar:

1. **No n8n, crie um HTTP Request node:**
   - URL: `http://evolution_api:8080/[endpoint]`
   - Header: `apikey: YOUR_API_KEY`

2. **Webhook do Evolution para n8n:**
   - Configure webhook URL: `http://n8n:5678/webhook/evolution`

3. **Exemplo de workflow:**
   - Receber mensagens do WhatsApp via webhook
   - Processar com n8n
   - Responder via Evolution API

## 📊 Monitoramento

### Health Check
```bash
curl https://evolution.seu-dominio.com/healthcheck
```

### Logs
```bash
# Logs do Evolution API
docker logs -f evolution_api

# Logs do PostgreSQL
docker logs -f evolution_postgres

# Logs do Redis
docker logs -f evolution_redis
```

### Métricas
- Monitoramento automático a cada 5 minutos
- Restart automático se falhar 3 vezes
- Notificações via webhook (se configurado)

## 🛠️ Comandos Úteis

### Gerenciamento de Containers
```bash
# Status dos containers
docker ps | grep evolution

# Reiniciar Evolution API
docker restart evolution_api

# Parar todos os serviços
cd /root/evolution && docker compose down

# Iniciar todos os serviços
cd /root/evolution && docker compose up -d
```

### API - Exemplos
```bash
# Listar instâncias
curl -H "apikey: YOUR_API_KEY" \
  https://evolution.seu-dominio.com/instance/fetchInstances

# Criar nova instância
curl -X POST https://evolution.seu-dominio.com/instance/create \
  -H "apikey: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "whatsapp-01", "qrcode": true}'

# Obter QR Code
curl -H "apikey: YOUR_API_KEY" \
  https://evolution.seu-dominio.com/instance/connect/whatsapp-01
```

## 🚨 Troubleshooting

### Evolution API não inicia
```bash
# Verificar logs
docker logs evolution_api --tail 50

# Verificar portas
netstat -tlnp | grep -E "8080|6381"

# Testar localmente
curl http://localhost:8080/healthcheck
```

### Problemas de conexão
```bash
# Verificar Nginx
systemctl status nginx
nginx -t

# Verificar SSL
certbot certificates

# Testar DNS
nslookup evolution.seu-dominio.com
```

### Banco de dados
```bash
# Acessar PostgreSQL
docker exec -it evolution_postgres psql -U evolution -d evolution_db

# Verificar Redis
docker exec -it evolution_redis redis-cli -a PASSWORD ping
```

## 📚 Recursos Adicionais

- [Documentação Oficial](https://doc.evolution-api.com)
- [GitHub Evolution API](https://github.com/EvolutionAPI/evolution-api)
- [Comunidade](https://evolution-api.com/community)
- [Exemplos de Integração](https://github.com/EvolutionAPI/evolution-api/tree/main/examples)

## 🤝 Suporte

Para problemas específicos:
1. Verifique os logs: `docker logs evolution_api`
2. Consulte `INSTALLATION_INFO.txt` no servidor
3. Abra uma issue no GitHub do projeto

## 📝 Notas Importantes

⚠️ **Segurança:**
- Mantenha a API Key segura
- Use sempre HTTPS em produção
- Configure firewall adequadamente
- Faça backups regulares

✅ **Melhores Práticas:**
- Monitore o uso de recursos
- Atualize regularmente
- Teste em ambiente de desenvolvimento primeiro
- Documente suas integrações

## 🔄 Atualizações

Para atualizar o Evolution API:
```bash
# 1. Fazer backup
/root/evolution/backup-evolution.sh

# 2. Atualizar imagem
docker pull atendai/evolution-api:latest

# 3. Reiniciar serviços
cd /root/evolution
docker compose down
docker compose up -d
```

---

**Versão:** Evolution API v2.3.2
**Data:** Setembro 2025
**Mantido por:** WB Digital Solutions