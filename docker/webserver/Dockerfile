# Webserver Docker Image
# Uses custom LAMP installation script from UNIX course
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Copy LAMP installation script
COPY lamp_install.sh /tmp/lamp_install.sh

# Make script executable and run it
RUN chmod +x /tmp/lamp_install.sh && \
    /tmp/lamp_install.sh

# Configure Apache to listen on all interfaces
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Create directory for hospital application
RUN mkdir -p /var/www/html

# Expose Apache port
EXPOSE 80

# Start Apache in foreground
CMD ["apache2ctl", "-D", "FOREGROUND"]

