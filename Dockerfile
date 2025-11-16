FROM ubuntu:latest

# Install packages and configure SSH
RUN apt-get update && \
    apt-get install -y openssh-server curl wget net-tools sudo && \
    mkdir -p /var/run/sshd && \
    echo 'root:12345' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Tailscale config
ENV TS_STATE_DIR=/var/lib/tailscale
RUN mkdir -p ${TS_STATE_DIR} /var/run/tailscale

# Build arg for auth key (pass at build time)
ARG TS_AUTHKEY

EXPOSE 22

# Start SSHD in foreground, Tailscale in background, auth, set prompt, and keep alive
CMD ["/bin/sh", "-c", "/usr/sbin/sshd -D & tailscaled --tun=userspace-networking --state=${TS_STATE_DIR}/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock & sleep 5 && tailscale up --authkey=${TS_AUTHKEY} --hostname=railway-vps && TS_IP=$(tailscale ip -4) && echo \"export PS1=\\\"\\u@$TS_IP:\\w# \\\"\" >> /root/.bashrc && echo \"Tailscale IP: $TS_IP\" && tail -f /dev/null"]
