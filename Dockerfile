FROM ubuntu:24.04
# Install everything: SSH, dev tools + Python for web server (no ttyd)
RUN apt-get update && apt-get install -y \
    openssh-server \
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
    && mkdir -p /var/run/sshd \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set root password
RUN echo 'root:xx200564#A' | chpasswd

# Download FRP 0.65.0 (Linux amd64) - fixed version to match FreeBSD server
RUN wget https://github.com/fatedier/frp/releases/download/v0.65.0/frp_0.65.0_linux_amd64.tar.gz && \
    tar xzvf frp_0.65.0_linux_amd64.tar.gz && \
    mv frp_0.65.0_linux_amd64/frpc /usr/local/bin/frpc && \
    chmod +x /usr/local/bin/frpc && \
    rm -rf frp_*

# Rest of your Dockerfile stays exactly the same (hostname EXO, prompt, MOTD, timezone, web dir, etc.)
# ... [keep all the lines you already have for prompt, MOTD, timezone, /www folder] ...

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
echo '' >> /frpc.toml && \
echo '[[proxies]]' >> /frpc.toml && \
echo 'name = railway_web' >> /frpc.toml && \
echo 'type = tcp' >> /frpc.toml && \
echo 'local_ip = 127.0.0.1' >> /frpc.toml && \
echo 'local_port = 7681' >> /frpc.toml && \
echo 'remote_port = 21113' >> /frpc.toml && \
echo 'use_encryption = true' >> /frpc.toml && \
echo 'use_compression = true' >> /frpc.toml && \
service ssh start && \
frpc -c /frpc.toml > /frp.log 2>&1 & \
python3 -m http.server 7681 --directory /www & \
echo \"=== READY === SSH: ssh root@exo.ssh.cx -p 20002 | Web: http://exo.ssh.cx\" && \
tail -f /dev/null"]
