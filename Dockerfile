FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip git curl

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql zip

# Enable Apache rewrite
RUN a2enmod rewrite

# Set Laravel public folder
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
 && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Fix Apache warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Allow .htaccess
RUN echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working dir
WORKDIR /var/www/html

# Copy project
COPY . .

# Create .env
RUN cp .env.example .env

# Install dependencies FIRST
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Generate key (safe now because vendor exists)
RUN php artisan key:generate

# Fix permissions
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 775 storage bootstrap/cache

# SQLite (optional)
RUN touch database/database.sqlite \
 && chmod 777 database/database.sqlite

EXPOSE 80

CMD ["apache2-foreground"]