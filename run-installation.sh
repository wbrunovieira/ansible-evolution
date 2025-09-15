#!/bin/bash

# Script de instalação do Evolution API via Ansible
# Baseado no ansible-n8n

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Evolution API Ansible Installation${NC}"
echo -e "${BLUE}========================================${NC}"

# Verificar Ansible
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Erro: Ansible não está instalado${NC}"
    echo "Instale com: pip install -r requirements.txt"
    exit 1
fi

# Verificar inventário
if [ ! -f "inventory/hosts.yml" ]; then
    echo -e "${RED}Erro: inventory/hosts.yml não encontrado${NC}"
    exit 1
fi

# Verificar vault
if [ -f "group_vars/all/vault.yml" ]; then
    # Checar se está criptografado
    if head -n1 group_vars/all/vault.yml | grep -q "ANSIBLE_VAULT"; then
        echo -e "${GREEN}✓ Vault está criptografado${NC}"
        VAULT_PASS="--ask-vault-pass"
    else
        echo -e "${YELLOW}⚠ Vault NÃO está criptografado${NC}"
        read -p "Deseja criptografar agora? (s/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            ansible-vault encrypt group_vars/all/vault.yml
            VAULT_PASS="--ask-vault-pass"
        else
            VAULT_PASS=""
        fi
    fi
else
    echo -e "${RED}Erro: group_vars/all/vault.yml não encontrado${NC}"
    exit 1
fi

# Testar conectividade
echo -e "\n${YELLOW}Testando conexão com servidor...${NC}"
if ansible -i inventory/hosts.yml all -m ping $VAULT_PASS; then
    echo -e "${GREEN}✓ Conexão estabelecida${NC}"
else
    echo -e "${RED}✗ Falha na conexão${NC}"
    exit 1
fi

# Menu de opções
echo -e "\n${GREEN}Escolha uma opção:${NC}"
echo "1) Instalação completa do Evolution API"
echo "2) Modo dry-run (simulação)"
echo "3) Instalação com debug verbose"
echo "4) Verificar sintaxe apenas"
echo "5) Atualizar Nginx/SSL apenas"
echo "6) Desinstalar Evolution API"
echo "7) Cancelar"

read -p "Opção: " choice

case $choice in
    1)
        echo -e "\n${GREEN}Iniciando instalação completa do Evolution API...${NC}"
        ansible-playbook -i inventory/hosts.yml deploy-evolution.yml $VAULT_PASS
        ;;
    2)
        echo -e "\n${YELLOW}Executando em modo dry-run...${NC}"
        ansible-playbook -i inventory/hosts.yml deploy-evolution.yml --check $VAULT_PASS
        ;;
    3)
        echo -e "\n${YELLOW}Instalação com debug verbose...${NC}"
        ansible-playbook -i inventory/hosts.yml deploy-evolution.yml -vvv $VAULT_PASS
        ;;
    4)
        echo -e "\n${YELLOW}Verificando sintaxe...${NC}"
        ansible-playbook -i inventory/hosts.yml deploy-evolution.yml --syntax-check
        ;;
    5)
        echo -e "\n${YELLOW}Atualizando Nginx/SSL...${NC}"
        if [ -f "update-nginx-ssl.yml" ]; then
            ansible-playbook -i inventory/hosts.yml update-nginx-ssl.yml $VAULT_PASS
        else
            echo -e "${RED}Playbook update-nginx-ssl.yml não encontrado${NC}"
        fi
        ;;
    6)
        echo -e "\n${RED}⚠ ATENÇÃO: Isso removerá completamente o Evolution API!${NC}"
        read -p "Tem certeza? Digite 'sim' para confirmar: " confirm
        if [ "$confirm" = "sim" ]; then
            if [ -f "uninstall-evolution.yml" ]; then
                ansible-playbook -i inventory/hosts.yml uninstall-evolution.yml $VAULT_PASS
            else
                echo -e "${RED}Playbook uninstall-evolution.yml não encontrado${NC}"
            fi
        else
            echo -e "${YELLOW}Desinstalação cancelada${NC}"
        fi
        ;;
    7)
        echo -e "${YELLOW}Instalação cancelada${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Opção inválida${NC}"
        exit 1
        ;;
esac

# Resultado final
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Processo concluído com sucesso!${NC}"
    echo -e "${GREEN}========================================${NC}"

    # Extrair informações do inventário
    SERVER_IP=$(grep ansible_host inventory/hosts.yml | awk '{print $2}')
    DOMAIN=$(grep evolution_domain inventory/hosts.yml | awk '{print $2}')
    PORT=$(grep evolution_port inventory/hosts.yml | awk '{print $2}')

    echo -e "\nPróximos passos:"
    echo -e "1. Acesse: ${GREEN}https://${DOMAIN}${NC}"
    echo -e "2. API Local: ${GREEN}http://${SERVER_IP}:${PORT}${NC}"
    echo -e "3. Documentação: ${GREEN}https://${DOMAIN}/docs${NC}"
    echo -e "4. Verifique logs: ssh root@${SERVER_IP} 'docker logs -f evolution_api'"
    echo -e "5. Info completa: ssh root@${SERVER_IP} 'cat /root/evolution/INSTALLATION_INFO.txt'"
    echo -e "\n${BLUE}Integração com n8n:${NC}"
    echo -e "  - n8n está em: http://localhost:5678"
    echo -e "  - Use Evolution API em: http://evolution_api:8080"
else
    echo -e "\n${RED}✗ Processo falhou${NC}"
    exit 1
fi