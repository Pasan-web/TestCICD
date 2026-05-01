FROM php:8.2-apache

# =========================
# System dependencies
# =========================
RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip git curl \
    && docker-php-ext-install pdo pdo_mysql zip

# =========================
# Apache config
# =========================
RUN a2enmod rewrite

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Fix Apache warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Allow Laravel routing
RUN echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# =========================
# Install Composer
# =========================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# =========================
# Copy application
# =========================
WORKDIR /var/www/html
COPY . .

# =========================
# Laravel setup (CRITICAL)
# =========================

# Create .env file
RUN cp .env.example .env

# Generate app key
RUN php artisan key:generate

# Use file session (avoid DB errors)
RUN sed -i 's/SESSION_DRIVER=.*/SESSION_DRIVER=file/' .env

# SQLite setup (optional but safe)
RUN touch database/database.sqlite

# Permissions (VERY IMPORTANT)
RUN chmod -R 777 storage bootstrap/cache database

# Install dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Clear caches
RUN php artisan config:clear \
 && php artisan cache:clear \
 && php artisan route:clear

# Run migrations (optional if using DB)
RUN php artisan migrate --force || true

# Final ownership
RUN chown -R www-data:www-data /var/www/html

# =========================
# Port
# =========================
EXPOSE 80

CMD ["apache2-foreground"]