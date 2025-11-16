FROM ubuntu:24.04

# Minimal install + create web root
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        openssh-server curl ca-certificates net-tools sudo python3-minimal && \
    mkdir -p /var/run/sshd /var/lib/tailscale /www && \
    echo 'root:12345' | chpasswd && \
    useradd -m -s /bin/bash user && \
    echo 'user:12345' | chpasswd && \
    usermod -aG sudo user && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Keep-alive page (Railway will show the real URL in the dashboard and deploy logs)
RUN echo '<!DOCTYPE html><html><head><title>Keep-Alive ✓</title><meta charset="utf-8">' > /www/index.html && \
    echo '<style>body{font-family: system-ui; text-align:center; padding:50px; background:#0d1117; color:#fff}</style></head><body>' >> /www/index.html && \
    echo '<h1>✅ Railway VPS Keep-Alive Page</h1>' >> /www/index.html && \
    echo '<p>This page is served so Railway sees real HTTP traffic and <strong>never suspends</strong> your project.</p>' >> /www/index.html && \
    echo '<p><strong>Your public Railway URL is this page itself</strong> → copy it from the Railway dashboard (or the deploy logs) and add it to <a href="https://uptimerobot.com" target="_blank">UptimeRobot</a> (free monitor every 5 minutes).</p>' >> /www/index.html && \
    echo '<hr><small>Tailscale IP is printed in container logs / MOTD</small></body></html>' >> /www/index.html

ENV TS_STATE_DIR=/var/lib/tailscale

# Everything in one clean CMD
CMD /bin/sh -c "\
    tailscaled --tun=userspace-networking --state=${TS_STATE_DIR}/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock & \
    sleep 15 && \
    tailscale up --authkey=${TS_AUTHKEY} --hostname=railway-vps --accept-dns=false --accept-risks=all --reset && \
    TS_IP=\$(tailscale ip -4) && \
    RAILWAY_URL=\"https://\$(echo \$RAILWAY_ENVIRONMENT_NAME | tr '[:upper:]' '[:lower:]')-\$RAILWAY_SERVICE_NAME.up.railway.app\" && \
    echo '==================================================================' && \
    echo '=================== TAILSCALE VPS READY ==========================' && \
    echo 'Tailscale IP      : \$TS_IP' && \
    echo 'SSH command       : ssh root@\$TS_IP  (password: 12345)' && \
    echo 'Keep-alive URL    : COPY THIS FROM DASHBOARD OR DEPLOY LOGS →' && \
    echo '                  https://your-service.up.railway.app' && \
    echo '                  (add it to UptimeRobot every 5 min to stay 100% alive)' && \
    echo '==================================================================' && \
    echo '' > /etc/motd && \
    echo '=== TAILSCALE VPS ===' >> /etc/motd && \
    echo \"Tailscale IP: \$TS_IP\" >> /etc/motd && \
    echo 'SSH: ssh root@'\$TS_IP' (pw 12345)' >> /etc/motd && \
    echo 'Keep-alive URL: check Railway dashboard → add to UptimeRobot' >> /etc/motd && \
    echo \"export PS1=\"\[\e[32m\]\u@\$TS_IP \[\e[34m\]\w\[\e[m\] \\$ \"' >> /root/.bashrc && \
    cp /root/.bashrc /home/user/.bashrc && chown user:user /home/user/.bashrc && \
    python3 -m http.server \${PORT:-8080} --directory /www --bind 0.0.0.0 & \
    exec /usr/sbin/sshd -D"
