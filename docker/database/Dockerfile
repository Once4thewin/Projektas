# Database Docker Image
# MySQL/MariaDB server for hospital management system
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV MYSQL_ROOT_PASSWORD=RootPass123!
ENV MYSQL_DATABASE=hospital_db
ENV MYSQL_USER=hospital_user
ENV MYSQL_PASSWORD=HospitalPass123!

# Install MySQL server
RUN apt-get update && \
    apt-get install -y mysql-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure MySQL for remote access
RUN sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Copy initialization script
COPY init.sql /docker-entrypoint-initdb.d/

# Create directory for MySQL data
RUN mkdir -p /var/lib/mysql

# Expose MySQL port
EXPOSE 3306

# Start MySQL
CMD ["mysqld_safe"]

