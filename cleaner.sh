#!/bin/bash

#UPDATE APT
sudo apt update && apt install bc

# check scripts folder existing
mkdir -p $HOME/scripts/

# Add cleaner.sh to scripts folder
tee $HOME/scripts/cleaner.sh > /dev/null <<EOF
#!/bin/bash
while true
do
    # remove syslog
    SIZE=\$(du -s /var/log | cut -f 1)
    GB=\$(echo "scale=0; \$SIZE/1024/1024" | bc)
    if [ \$(echo "\$GB > 10" | bc) -eq 1 ]; then
      echo "\$(date) | \$GB GB - clean syslog"
      rm /var/log/syslog*
    fi

    # remove subspace log files
    SIZE=\$(du -s \$HOME/.local/share/subspace-cli/logs | cut -f 1)
    GB=\$(echo "scale=0; \$SIZE/1024/1024" | bc)
    if [ \$(echo "\$GB > 10" | bc) -eq 1 ]; then
      echo "\$(date) | \$GB GB - clean subspace_log"
      rm /root/.local/share/subspace-cli/logs/*
    fi

    sleep 6
done

EOF

chmod +x $HOME/scripts/cleaner.sh

# Create logs cleaner service file
sudo tee /etc/systemd/system/cleaner.service > /dev/null <<EOF
[Unit]
Description=Logs Cleaner Service
After=network.target

[Service]
User=$USER
ExecStart=$HOME/scripts/cleaner.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start cleaner service file
systemctl daemon-reload
systemctl enable cleaner
systemctl restart cleaner
