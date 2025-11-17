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
    cat > /frpc.toml <<EOF
[common]
server_addr = s3.serv00.net
server_port = 17000
token = a7medVPS2025SuperSecretTokenXx200564#A12345

[[proxies]]
name = railway_ssh
type = tcp
local_ip = 127.0.0.1
local_port = 22
remote_port = 21113
use_encryption = true
use_compression = true
EOF
    service ssh start && \
    frpc -c /frpc.toml > /frp.log 2>&1 & \
    ttyd -p 7681 /bin/login -t titleFixed='a7med Railway VPS' -t fontSize=17 & \
    echo \"=== READY === SSH: ssh root@s3.serv00.net -p 21113   Web on port 7681\" && \
    tail -f /dev/null"]
