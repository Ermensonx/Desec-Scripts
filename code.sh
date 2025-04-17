#!/bin/bash

# Script de reinstalação completa do SaaS Restaurante
# Remove arquivos antigos, banco de dados e reinstala tudo do zero

# Configurações
DB_NAME="restaurante_saas"
DB_USER="restauranteuser"
DB_PASSWORD="senha_segura_aqui"
REPO_URL="https://github.com/seu-usuario/seu-repositorio.git"  # Substitua pelo seu repositório
APP_DIR="/var/www/restaurante-saas"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
  echo -e "${GREEN}>>> $1${NC}"
}
warn() {
  echo -e "${YELLOW}>>> AVISO: $1${NC}"
}
error() {
  echo -e "${RED}>>> ERRO: $1${NC}" && exit 1
}

# Verifica root
if [ "$EUID" -ne 0 ]; then
  error "Este script deve ser executado como root."
fi

log "Reiniciando instalação do SaaS Restaurante..."

# Parar serviços
log "Parando serviços..."
systemctl stop nginx || warn "Nginx já estava parado."

# Remover arquivos anteriores
log "Removendo arquivos anteriores em $APP_DIR..."
rm -rf $APP_DIR || warn "Falha ao remover arquivos anteriores."

# Remover Nginx site config
log "Removendo configuração Nginx..."
rm -f /etc/nginx/sites-enabled/restaurante-saas /etc/nginx/sites-available/restaurante-saas

# Resetar banco de dados
log "Resetando banco de dados..."
sudo -u postgres dropdb $DB_NAME || warn "Banco já estava excluído."
sudo -u postgres dropuser $DB_USER || warn "Usuário já estava excluído."

# Recriar banco e usuário
log "Recriando banco de dados e usuário..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"

# Clonar projeto
log "Clonando repositório..."
git clone $REPO_URL $APP_DIR || error "Falha ao clonar repositório."

cd $APP_DIR || error "Falha ao entrar no diretório."

# Instalar dependências
log "Instalando dependências PHP..."
composer install --no-interaction || warn "Falha composer."

log "Instalando dependências JS..."
npm install || warn "Falha npm."
npm run build || npm run dev || warn "Falha ao compilar frontend."

# .env
log "Configurando .env..."
cp .env.example .env

sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env

log "Gerando chave da aplicação..."
php artisan key:generate

log "Executando migrações..."
php artisan migrate --force
php artisan db:seed --force

log "Criando roles..."
php artisan create:roles || warn "Comando create:roles não definido."

# Permissões
log "Ajustando permissões..."
chown -R www-data:www-data $APP_DIR
chmod -R 775 storage bootstrap/cache

# Nginx
log "Configurando Nginx..."
cat > /etc/nginx/sites-available/restaurante-saas << EOF
server {
    listen 80;
    server_name restaurante-saas.local localhost;
    root $APP_DIR/public;

    index index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\. {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/restaurante-saas /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx || warn "Erro ao reiniciar nginx."

log "Instalação concluída. Acesse em: http://localhost ou http://restaurante-saas.local"
log "Credenciais padrão: admin@example.com / password"
