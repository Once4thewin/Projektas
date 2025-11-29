# Client Browser Docker Image
# Contains Opera, Chrome, and Midori browsers for accessing the hospital system
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install desktop environment and browsers
RUN apt-get update && \
    apt-get install -y \
    xfce4 \
    xfce4-goodies \
    x11vnc \
    xvfb \
    wget \
    curl \
    gnupg \
    ca-certificates && \
    apt-get clean

# Install Opera browser
RUN wget -qO- https://deb.opera.com/archive.key | apt-key add - && \
    echo "deb [arch=amd64] https://deb.opera.com/opera-stable/ stable non-free" >> /etc/apt/sources.list.d/opera.list && \
    apt-get update && \
    apt-get install -y opera-stable

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable

# Install Midori browser
RUN apt-get install -y midori

# Install VNC server for remote access
RUN apt-get install -y tigervnc-standalone-server tigervnc-common

# Create VNC password file (default password: vncpass)
RUN mkdir -p ~/.vnc && \
    echo "vncpass" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Create startup script
RUN echo '#!/bin/bash\n\
Xvfb :1 -screen 0 1024x768x24 &\n\
export DISPLAY=:1\n\
startxfce4 &\n\
x11vnc -display :1 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever &\n\
tail -f /dev/null' > /start.sh && \
    chmod +x /start.sh

# Expose VNC port
EXPOSE 5900

# Start VNC and desktop environment
CMD ["/start.sh"]

