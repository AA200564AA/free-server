FROM ubuntu:24.04

# Install essentials
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
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Keep-alive page
RUN echo '<!DOCTYPE html><html><head><title>Keep-Alive ✓</title><meta charset="utf-8">' > /www/index.html && \
    echo '<style>body{font-family:system-ui;text-align:center;padding:50px;background:#0d1117;color:#fff}</style></head><body>' >> /www/index.html && \
    echo '<h1>✅ Railway + Tailscale VPS Active</h1>' >> /www/index.html && \
    echo '<p>This page keeps Railway from ever suspending your project.</p>' >> /www/index.html && \
    echo '<p><strong>→ Copy the public URL from Railway dashboard → Domains</strong><br>' >> /www/index.html && \
    echo 'Add it to <a href="https://uptimerobot.com" target="_blank">UptimeRobot</a> (free, every 5 min) → 100% always-on</p>' >> /www/index.html && \
    echo '<hr><small>Tailscale IP is in container logs & MOTD</small></body></html>' >> /www/index.html

# Startup script (no more quoting hell)
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock &' >> /start.sh && \
    echo 'sleep 15' >> /start.sh && \
    echo 'tailscale up --authkey=${TS_AUTHKEY} --hostname=railway-vps --accept-dns=false --accept-risks=all --reset' >> /start.sh && \
    echo 'TS_IP=$(tailscale ip -4)' >> /start.sh && \
    echo 'echo "================================================================="' >> /start.sh && \
    echo 'echo "=================== TAILSCALE VPS READY ========================="' >> /start.sh && \
    echo "echo \"Tailscale IP      : $TS_IP\"" >> /start.sh && \
    echo "echo \"SSH command       : ssh root@$TS_IP   (password: 12345)\"" >> /start.sh && \
    echo 'echo "Keep-alive URL    : Check Railway dashboard → Domains → copy the .up.railway.app URL"' >> /start.sh && \
    echo 'echo "                  Add it to UptimeRobot every 5 min → never shuts down"' >> /start.sh && \
    echo 'echo "================================================================="' >> /start.sh && \
    echo "echo \"Tailscale IP: $TS_IP\" > /etc/motd" >> /start.sh && \
    echo "echo \"SSH: ssh root@$TS_IP (pw 12345)\" >> /etc/motd" >> /start.sh && \
    echo 'echo "Keep-alive: copy URL from Railway → Domains and ping with UptimeRobot" >> /etc/motd' >> /start.sh && \
    echo "echo 'export PS1=\"\\[\e[32m\\]\\u@$TS_IP \\[\e[34m\\]\\w\\[\e[m\\] \\$ \"' >> /root/.bashrc" >> /start.sh && \
    echo "cp /root/.bashrc /home/user/.bashrc && chown user:user /home/user/.bashrc" >> /start.sh && \
    echo "python3 -m http.server \${PORT:-8080} --directory /www --bind 0.0.0.0 &" >> /start.sh && \
    echo 'exec /usr/sbin/sshd -D' >> /start.sh && \
    chmod +x /start.sh

ENV TS_STATE_DIR=/var/lib/tailscale

# Volume for persistent Tailscale state (add this in Railway dashboard!)
# Service → Settings → Volumes → Add → Path: /var/lib/tailscale

CMD ["/start.sh"]
