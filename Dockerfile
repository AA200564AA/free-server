FROM ubuntu:24.04
# Install everything: SSH, ttyd, FRP + dev tools + HAProxy for PROXY protocol
RUN apt-get update && apt-get install -y \
    openssh-server \
    ttyd \
    curl \
    wget \
    screen \
    net-tools \
    iputils-ping \
    python3 \
    python3-pip \
    git \
    vim \
    nano \
    htop \
    build-essential \
    gcc \
    g++ \
    make \
    nodejs \
    npm \
    sudo \
    unzip \
    zip \
    tree \
    jq \
    haproxy \
    && mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/Port 22/Port 2222/' /etc/ssh/sshd_config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# Set root password
RUN echo 'root:xx200564#A' | chpasswd
# Download latest FRP automatically
RUN FRP_VER=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//') && \
    wget https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_amd64.tar.gz && \
    tar xzvf frp_${FRP_VER}_linux_amd64.tar.gz && \
    mv frp_${FRP_VER}_linux_amd64/frpc /usr/local/bin/frpc && \
    chmod +x /usr/local/bin/frpc && \
    rm -rf frp_*
# Set /etc/hostname (try to make hostname command show EXO, though Railway may override)
RUN echo "EXO" > /etc/hostname && \
    echo "127.0.0.1 EXO" >> /etc/hosts
# Custom bash prompt for root and new users + alias for hostname
RUN echo '# Custom VPS-like prompt: [user@hostname]:<dir>$' >> /root/.bashrc && \
    echo 'export PS1="[\u@EXO]:<\w>\$ "' >> /root/.bashrc && \
    echo 'alias hostname="echo EXO"' >> /root/.bashrc && \
    echo '# Custom VPS-like prompt for new users' >> /etc/skel/.bashrc && \
    echo 'export PS1="[\u@EXO]:<\w>\$ "' >> /etc/skel/.bashrc && \
    echo 'alias hostname="echo EXO"' >> /etc/skel/.bashrc
# Dynamic MOTD showing EXO hostname
RUN chmod -x /etc/update-motd.d/* && \
    echo '#!/bin/bash' > /etc/update-motd.d/00-exo && \
    echo 'echo "====================================="' >> /etc/update-motd.d/00-exo && \
    echo 'echo " Welcome to EXO VPS"' >> /etc/update-motd.d/00-exo && \
    echo 'echo " Hostname: EXO | Uptime: $(uptime -p)"' >> /etc/update-motd.d/00-exo && \
    echo 'echo " Users: $(who | wc -l) | Load: $(uptime | awk '\''{print $10}'\'')"' >> /etc/update-motd.d/00-exo && \
    echo 'echo "====================================="' >> /etc/update-motd.d/00-exo && \
    chmod +x /etc/update-motd.d/00-exo
# HAProxy config for PROXY protocol (to preserve real client IP for SSH)
RUN echo 'global' > /etc/haproxy/haproxy.cfg && \
    echo '    log /dev/log local0' >> /etc/haproxy/haproxy.cfg && \
    echo '    log /dev/log local1 notice' >> /etc/haproxy/haproxy.cfg && \
    echo '' >> /etc/haproxy/haproxy.cfg && \
    echo 'defaults' >> /etc/haproxy/haproxy.cfg && \
    echo '    log global' >> /etc/haproxy/haproxy.cfg && \
    echo '    mode tcp' >> /etc/haproxy/haproxy.cfg && \
    echo '    option tcplog' >> /etc/haproxy/haproxy.cfg && \
    echo '' >> /etc/haproxy/haproxy.cfg && \
    echo 'frontend ssh' >> /etc/haproxy/haproxy.cfg && \
    echo '    bind *:22' >> /etc/haproxy/haproxy.cfg && \
    echo '    default_backend ssh_backend' >> /etc/haproxy/haproxy.cfg && \
    echo '' >> /etc/haproxy/haproxy.cfg && \
    echo 'backend ssh_backend' >> /etc/haproxy/haproxy.cfg && \
    echo '    server ssh 127.0.0.1:2222 send-proxy-v2' >> /etc/haproxy/haproxy.cfg
# Set timezone to EET (Egypt)
RUN ln -sf /usr/share/zoneinfo/Africa/Cairo /etc/localtime && \
    echo "Africa/Cairo" > /etc/timezone
EXPOSE 22 7681
CMD ["/bin/bash", "-c", "\
echo '[common]' > /frpc.toml && \
echo 'server_addr = s3.serv00.net' >> /frpc.toml && \
echo 'server_port = 17000' >> /frpc.toml && \
echo 'token = a7medVPS2025SuperSecretTokenXx200564#A12345' >> /frpc.toml && \
echo '' >> /frpc.toml && \
echo '[[proxies]]' >> /frpc.toml && \
echo 'name = railway_ssh' >> /frpc.toml && \
echo 'type = tcp' >> /frpc.toml && \
echo 'local_ip = 127.0.0.1' >> /frpc.toml && \
echo 'local_port = 22' >> /frpc.toml && \
echo 'remote_port = 20002' >> /frpc.toml && \
echo 'use_encryption = true' >> /frpc.toml && \
echo 'use_compression = true' >> /frpc.toml && \
echo 'proxy_protocol_version = v2' >> /frpc.toml && \
service ssh start && \
haproxy -f /etc/haproxy/haproxy.cfg & \
frpc -c /frpc.toml > /frp.log 2>&1 & \
ttyd -p 7681 /bin/login -t titleFixed='a7medRailway VPS' -t fontSize=17 & \
echo \"=== READY === SSH: ssh root@exo.ssh.cx -p 20002 Web on port 7681\" && \
tail -f /dev/null"]
