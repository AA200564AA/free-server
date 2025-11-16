FROM ubuntu:latest

# تثبيت الحزم المطلوبة
RUN apt-get update && \
    apt-get install -y openssh-server curl wget net-tools sudo && \
    mkdir /var/run/sshd && \
    echo 'root:12345' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# تثبيت Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# إعداد متغير البيئة
ENV TS_STATE_DIR=/var/lib/tailscale

# بدء الخدمات عند تشغيل الحاوية
CMD /bin/bash -c "\
    /usr/sbin/sshd && \
    tailscaled --tun=userspace-networking --state=${TS_STATE_DIR}/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock & \
    sleep 5 && \
    tailscale up --authkey=${TS_AUTHKEY} --hostname=railway-vps && \
    TS_IP=\$(tailscale ip -4) && \
    echo 'export PS1=\"\\u@\${TS_IP}:\\w# \"' >> /root/.bashrc && \
    echo \"Tailscale IP: \$TS_IP\" && \
    tail -f /dev/null"
