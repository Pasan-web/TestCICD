FROM php:8.2-apache

# =========================
# System dependencies
# =========================
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    git \
    curl

# =========================
# PHP extensions
# =========================
RUN docker-php-ext-install pdo_mysql zip

# =========================
# Apache config
# =========================
RUN a2enmod rewrite

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Fix Apache permission (VERY IMPORTANT for 403)
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

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
# Permissions (IMPORTANT FIX)
# =========================
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 775 storage bootstrap/cache

# =========================
# SQLite fix (if used)
# =========================
RUN touch database/database.sqlite \
 && chmod 777 database/database.sqlite

# =========================
# Laravel setup
# =========================
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

RUN php artisan key:generate || true
RUN php artisan config:clear || true
RUN php artisan cache:clear || true
RUN php artisan route:clear || true

# =========================
# Apache port
# =========================
EXPOSE 80

CMD ["apache2-foreground"]