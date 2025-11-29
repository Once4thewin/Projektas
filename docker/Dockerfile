FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Copy LAMP installation script from UNIX course
COPY lamp_install.sh /tmp/lamp_install.sh

# Make script executable and run it
RUN chmod +x /tmp/lamp_install.sh && \
    /tmp/lamp_install.sh

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]

