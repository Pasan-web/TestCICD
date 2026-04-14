FROM php:8.2-apache

# Install dependencies
RUN apt-get update && \
    apt-get install -y libzip-dev zip curl git unzip && \
    docker-php-ext-install pdo_mysql zip

# Enable Apache rewrite
RUN a2enmod rewrite

# Set Apache document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Fix Apache permissions (IMPORTANT FOR 403)
RUN echo '<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf

# Copy application
COPY . /var/www/html

WORKDIR /var/www/html

# Permissions AFTER copy (IMPORTANT FIX)
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 775 storage bootstrap/cache

# SQLite file (optional)
RUN touch database/database.sqlite

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN composer install --no-interaction --prefer-dist

EXPOSE 80