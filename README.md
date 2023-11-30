## Utool - Quick Server Deployment and Configuration Tool

Utool is a powerful tool support configuring servers, it verry lightweight and providing an efficient and time-saving experience for system administrators

### How to install UTool

```bash
cd && mkdir .utool && cd .utool
curl -L -o utool.tar.gz https://github.com/leanhthang/server-setup/archive/refs/tags/v0.0.1.tar.gz
tar -xzf utool.tar.gz && mv server-setup-*/* . && rm utool.tar.gz server-setup-*/*  && cd
echo "alias utool='source .utool/utool.sh'" | sudo tee -a ~/.bashrc
source ~/.bashrc
```
