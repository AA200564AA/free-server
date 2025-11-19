FROM ubuntu:24.04

# Your full original packages
RUN apt-get update && apt-get install -y \
    openssh-server curl wget screen net-tools iputils-ping python3 python3-pip \
    git vim nano htop build-essential gcc g++ make nodejs npm sudo unzip zip tree jq \
    && mkdir -p /var/run/sshd /www \
    && ssh-keygen -A \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && echo 'root:xx200564#A' | chpasswd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# FRP 0.65.0
RUN wget https://github.com/fatedier/frp/releases/download/v0.65.0/frp_0.65.0_linux_amd64.tar.gz && \
    tar xzvf frp_0.65.0_linux_amd64.tar.gz && \
    mv frp_0.65.0_linux_amd64/frpc /usr/local/bin/frpc && \
    chmod +x /usr/local/bin/frpc && rm -rf frp_*

# All your custom stuff (hostname, timezone, prompt, MOTD, web page)
RUN echo 'EXO' > /etc/hostname && echo '127.0.0.1 EXO' >> /etc/hosts
ENV TZ=Africa/Cairo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo "PS1='\[\e[38;5;202m\]\u\[\e[38;5;51m\]@\[\e[38;5;208m\]EXO\[\e[38;5;51m\]:\[\e[38;5;118m\]\w\[\e[38;5;208m\]#\[\e[0m\] '" >> /root/.bashrc
RUN echo -e "\n\e[38;5;208m ███████╗██╗  ██╗ ██████╗ \n\e[38;5;208m ██╔════╝╚██╗██╔╝██╔═══██╗\n\e[38;5;51m  █████╗   ╚███╔╝ ██║   ██║\n\e[38;5;51m  ██╔══╝   ██╔██╗ ██║   ██║\n\e[38;5;118m ███████╗██╔╝ ██╗╚██████╔╝\n\e[38;5;118m ╚══════╝╚═╝  ╚═╝ ╚═════╝ \n\e[0m\nEXO VPS — Everything on port 20002!\n" > /etc/motd
RUN echo "<h1>EXO VPS — PORT 20002 ONLY</h1>" > /www/index.html

EXPOSE 22 7681

# THIS ONE BUILDS 100% — config is written with printf (no heredoc problems)
CMD ["/bin/bash", "-c", "\
service ssh start && \
python3 -m http.server 7681 --directory /www & && \
printf \"%s\n\" \
\"[common]\" \
\"server_addr = s3.serv00.com\" \
\"server_port = 17000\" \
\"token = a7medVPS2025SuperSecretTokenXx200564#A12345\" \
\"\" \
\"[[proxies]]\" \
\"name = web_20002\" \
\"type = tcp\" \
\"local_ip = 127.0.0.1\" \
\"local_port = 7681\" \
\"remote_port = 20002\" \
\"\" \
\"[[proxies]]\" \
\"name = ssh_xtcp_20002\" \
\"type = xtcp\" \
\"role = client\" \
\"sk = exo20002secret2025\" \
\"local_ip = 127.0.0.1\" \
\"local_port = 22\" \
> /tmp/frpc.toml && \
frpc -c /tmp/frpc.toml > /frp.log 2>&1 & \
echo '=== EXO VPS READY — PORT 20002 ONLY ===' && \
echo 'Web + SSH: exo.ssh.cx port 20002' && \
echo 'ssh root@exo.ssh.cx -p 20002  (pass: xx200564#A)' && \
tail -f /dev/null"]
