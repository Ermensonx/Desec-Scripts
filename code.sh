#!/bin/bash

# Script de instalação automatizada do SaaS para Restaurantes
# Para uso em ambiente de intranet/teste
# ----------------------------------------

# Configurações - Edite estas variáveis conforme necessário
DB_NAME="restaurante_saas"
DB_USER="restauranteuser"
DB_PASSWORD="senha_segura_aqui"
REPO_URL="https://github.com/seu-usuario/seu-repositorio.git" # Substitua pelo seu repositório
APP_NAME="Restaurante SaaS"
APP_ENV="local"
APP_DEBUG="true"
APP_URL="http://localhost"
TIMEZONE="America/Sao_Paulo"
LOCALE="pt_BR"

# Cores para saída
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para exibir mensagens de progresso
show_message() {
    echo -e "${GREEN}>>> $1${NC}"
}

# Função para exibir mensagens de aviso
show_warning() {
    echo -e "${YELLOW}>>> AVISO: $1${NC}"
}

# Função para exibir mensagens de erro
show_error() {
    echo -e "${RED}>>> ERRO: $1${NC}"
    exit 1
}

# Verifica se o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
    show_error "Este script precisa ser executado como root (sudo)."
fi

# Início da instalação
show_message "Iniciando a instalação do SaaS para Restaurantes..."
show_message "Este processo pode levar algum tempo. Por favor, aguarde."

# Atualiza o sistema
show_message "Atualizando o sistema..."
apt update && apt upgrade -y || show_error "Falha ao atualizar o sistema."

# Define o timezone
show_message "Configurando timezone..."
timedatectl set-timezone $TIMEZONE || show_warning "Falha ao configurar o timezone."

# Instala pacotes essenciais
show_message "Instalando pacotes essenciais..."
apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg || show_error "Falha ao instalar pacotes essenciais."

# Instala o Nginx
show_message "Instalando Nginx..."
apt install -y nginx || show_error "Falha ao instalar o Nginx."
systemctl enable nginx || show_warning "Falha ao habilitar o Nginx."
systemctl start nginx || show_warning "Falha ao iniciar o Nginx."

# Adiciona repositório PHP
show_message "Adicionando repositório PHP..."
add-apt-repository ppa:ondrej/php -y || show_warning "Falha ao adicionar repositório PHP. Tentando continuar..."
apt update || show_warning "Falha ao atualizar índices após adicionar repositório PHP."

# Instala PHP e extensões
show_message "Instalando PHP 8.2 e extensões..."
apt install -y php8.2-fpm php8.2-cli php8.2-common php8.2-pgsql php8.2-gd php8.2-xml php8.2-curl php8.2-mbstring php8.2-zip php8.2-bcmath php8.2-intl php8.2-readline || show_error "Falha ao instalar o PHP."

# Instala o PostgreSQL
show_message "Instalando PostgreSQL..."
apt install -y postgresql postgresql-contrib || show_error "Falha ao instalar o PostgreSQL."

# Configura o PostgreSQL
show_message "Configurando banco de dados PostgreSQL..."
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" || show_warning "Falha ao criar banco de dados. Pode já existir."
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" || show_warning "Falha ao criar usuário. Pode já existir."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" || show_warning "Falha ao conceder privilégios."
sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;" || show_warning "Falha ao definir usuário como superuser."

# Instala o Composer
show_message "Instalando Composer..."
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer || show_error "Falha ao instalar o Composer."

# Instala o Node.js e npm
show_message "Instalando Node.js e npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash - || show_warning "Falha ao configurar repositório Node.js."
apt install -y nodejs || show_error "Falha ao instalar o Node.js."
npm install -g npm@latest || show_warning "Falha ao atualizar o npm."

# Configura o diretório da aplicação
show_message "Configurando diretório da aplicação..."
mkdir -p /var/www/restaurante-saas || show_error "Falha ao criar diretório da aplicação."

# Clonar o repositório ou usar um diretório local
if [ -n "$REPO_URL" ]; then
    show_message "Clonando repositório..."
    git clone $REPO_URL /var/www/restaurante-saas || show_error "Falha ao clonar o repositório."
else
    show_warning "Nenhum repositório especificado. Você precisará copiar os arquivos manualmente para /var/www/restaurante-saas"
fi

# Configura permissões
show_message "Configurando permissões..."
chown -R www-data:www-data /var/www/restaurante-saas || show_warning "Falha ao configurar permissões de proprietário."
find /var/www/restaurante-saas -type f -exec chmod 664 {} \; || show_warning "Falha ao configurar permissões de arquivos."
find /var/www/restaurante-saas -type d -exec chmod 775 {} \; || show_warning "Falha ao configurar permissões de diretórios."

# Navega para o diretório da aplicação
cd /var/www/restaurante-saas || show_error "Falha ao acessar diretório da aplicação."

# Instala dependências PHP
show_message "Instalando dependências PHP..."
composer install --no-interaction || show_warning "Falha ao instalar dependências PHP."

# Configura o arquivo .env
show_message "Configurando o arquivo .env..."
cp .env.example .env || show_warning "Falha ao criar arquivo .env. Tentando criar manualmente..."

if [ ! -f .env ]; then
    cat > .env << EOF
APP_NAME="$APP_NAME"
APP_ENV=$APP_ENV
APP_KEY=
APP_DEBUG=$APP_DEBUG
APP_URL=$APP_URL

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=$DB_NAME
DB_USERNAME=$DB_USER
DB_PASSWORD=$DB_PASSWORD

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="\${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_HOST=
PUSHER_PORT=443
PUSHER_SCHEME=https
PUSHER_APP_CLUSTER=mt1

VITE_PUSHER_APP_KEY="\${PUSHER_APP_KEY}"
VITE_PUSHER_HOST="\${PUSHER_HOST}"
VITE_PUSHER_PORT="\${PUSHER_PORT}"
VITE_PUSHER_SCHEME="\${PUSHER_SCHEME}"
VITE_PUSHER_APP_CLUSTER="\${PUSHER_APP_CLUSTER}"
EOF
    show_message "Arquivo .env criado manualmente."
fi

# Gera a chave da aplicação
show_message "Gerando chave da aplicação..."
php artisan key:generate || show_warning "Falha ao gerar chave da aplicação."

# Atualiza as configurações do arquivo .env
show_message "Atualizando configurações no arquivo .env..."
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=pgsql/" .env || show_warning "Falha ao atualizar DB_CONNECTION."
sed -i "s/DB_HOST=.*/DB_HOST=127.0.0.1/" .env || show_warning "Falha ao atualizar DB_HOST."
sed -i "s/DB_PORT=.*/DB_PORT=5432/" .env || show_warning "Falha ao atualizar DB_PORT."
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env || show_warning "Falha ao atualizar DB_DATABASE."
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env || show_warning "Falha ao atualizar DB_USERNAME."
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env || show_warning "Falha ao atualizar DB_PASSWORD."

# Instala dependências Node.js
show_message "Instalando dependências Node.js..."
npm install || show_warning "Falha ao instalar dependências Node.js."

# Compila assets
show_message "Compilando assets..."
npm run build || show_warning "Falha ao compilar assets. Tentando com 'npm run dev'..."
if [ $? -ne 0 ]; then
    npm run dev || show_warning "Falha ao compilar assets com 'npm run dev'."
fi

# Configurar permissões de armazenamento
show_message "Configurando permissões de armazenamento..."
chmod -R 775 storage bootstrap/cache || show_warning "Falha ao configurar permissões de armazenamento."
chown -R www-data:www-data storage bootstrap/cache || show_warning "Falha ao configurar proprietário do armazenamento."

# Executa migrações e seeders
show_message "Executando migrações e seeders..."
php artisan migrate --force || show_warning "Falha ao executar migrações."
php artisan db:seed --force || show_warning "Falha ao executar seeders."

# Cria roles
show_message "Criando roles..."
php artisan create:roles || show_warning "Falha ao criar roles. Verifique se o comando está definido."

# Otimiza a aplicação
show_message "Otimizando a aplicação..."
php artisan optimize || show_warning "Falha ao otimizar a aplicação."
php artisan config:cache || show_warning "Falha ao criar cache de configurações."
php artisan route:cache || show_warning "Falha ao criar cache de rotas."
php artisan view:cache || show_warning "Falha ao criar cache de views."

# Configura o Nginx
show_message "Configurando o Nginx..."
cat > /etc/nginx/sites-available/restaurante-saas << EOF
server {
    listen 80;
    server_name restaurante-saas.local localhost;
    root /var/www/restaurante-saas/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Ativa o site e reinicia o Nginx
show_message "Ativando configuração do Nginx..."
ln -sf /etc/nginx/sites-available/restaurante-saas /etc/nginx/sites-enabled/ || show_warning "Falha ao criar link simbólico."
rm -f /etc/nginx/sites-enabled/default || show_warning "Falha ao remover configuração padrão."
nginx -t || show_warning "Teste de configuração do Nginx falhou."
systemctl restart nginx || show_warning "Falha ao reiniciar o Nginx."

# Obtém o endereço IP da máquina
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Instalação concluída
show_message "Instalação concluída com sucesso!"
show_message "Acesse a aplicação em: http://$IP_ADDRESS"
show_message "Credenciais padrão: admin@example.com / password"

# Instruções adicionais
echo -e "${YELLOW}---------------------------------------------${NC}"
echo -e "${YELLOW}INSTRUÇÕES ADICIONAIS:${NC}"
echo -e "${YELLOW}1. Adicione o seguinte ao arquivo hosts dos computadores que acessarão o sistema:${NC}"
echo -e "${YELLOW}   $IP_ADDRESS restaurante-saas.local${NC}"
echo -e "${YELLOW}2. Depois disso, você poderá acessar usando: http://restaurante-saas.local${NC}"
echo -e "${YELLOW}---------------------------------------------${NC}"

show_message "Obrigado por usar o script de instalação do Restaurante SaaS!"
