FROM ubuntu:24.04

# Install everything
RUN apt-get update && apt-get install -y \
    openssh-server \
    ttyd \
    curl \
    wget \
    screen \
    net-tools && \
    mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Hardcode root password as you requested
RUN echo 'root:xx200564#A' | chpasswd

# Download latest frp automatically (always up to date)
RUN FRP_VER=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//') && \
    wget https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_amd64.tar.gz && \
    tar xzvf frp_${FRP_VER}_linux_amd64.tar.gz && \
    mv frp_${FRP_VER}_linux_amd64/frpc /usr/local/bin/frpc && \
    chmod +x /usr/local/bin/frpc && \
    rm -rf frp_*

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
    service ssh start && \
    frpc -c /frpc.toml > /frp.log 2>&1 & \
    ttyd -p 7681 /bin/login -t titleFixed='a7medRailway VPS' -t fontSize=17 & \
    echo \"=== READY === SSH: ssh root@exo.ssh.cx -p 20002   Web on port 7681\" && \
    tail -f /dev/null"]
