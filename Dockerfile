FROM ubuntu:24.04

# Packages + SSH + root password
RUN apt-get update && apt-get install -y \
    openssh-server curl wget screen net-tools iputils-ping python3 python3-pip \
    git vim nano htop build-essential gcc g++ make nodejs npm sudo unzip zip tree jq \
    && mkdir -p /var/run/sshd /www \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo 'root:xx200564#A' | chpasswd \
    && echo "<h1>EXO VPS - PORT 20002 ONLY</h1>" > /www/index.html \
    && apt-get clean

# FRP client
RUN wget https://github.com/fatedier/frp/releases/download/v0.65.0/frp_0.65.0_linux_amd64.tar.gz && \
    tar xzvf frp_0.65.0_linux_amd64.tar.gz && \
    mv frp_0.65.0_linux_amd64/frpc /usr/local/bin/frpc && \
    chmod +x /usr/local/bin/frpc && rm -rf frp_*

EXPOSE 22 7681

# THIS ONE NEVER FAILS — array style CMD (Railway loves it)
CMD ["bash", "-c", "\
obf = true && \
echo 'EXO' > /etc/hostname && \
echo '127.0.0.1 localhost EXO' > /etc/hosts && \
ln -sf /usr/share/zoneinfo/Africa/Cairo /etc/localtime && \
echo 'Africa/Cairo' > /etc/timezone && \
echo \"PS1='\[\e[38;5;202m\]\u\[\e[38;5;51m\]@\[\e[38;5;208m\]EXO\[\e[38;5;51m\]:\[\e[38;5;118m\]\w\[\e[38;5;208m\]#\[\e[0m\] '\" > /root/.bashrc && \
service ssh start && \
python3 -m http.server 7681 --directory /www & \
printf '[common]\nserver_addr = s3.serv00.com\nserver_port = 17000\ntoken = a7medVPS2025SuperSecretTokenXx200564#A12345\n\n[[proxies]]\nname = web_20002\ntype = tcp\nlocal_ip = 127.0.0.1\nlocal_port = 7681\nremote_port = 20002\n\n[[proxies]]\nname = ssh_xtcp_20002\ntype = xtcp\nrole = client\nsk = exo20002secret2025\nlocal_ip = 127.0.0.1\nlocal_port = 22\n' > /frpc.toml && \
frpc -c /frpc.toml > /frp.log 2>&1 & \
echo '=== EXO VPS IS ALIVE ON PORT 20002 ONLY ===' && \
echo 'Web + SSH → https://exo.ssh.cx -p 20002' && \
echo 'ssh root@exo.ssh.cx -p 20002 (pass: xx200564#A)' && \
tail -f /dev/null"]
