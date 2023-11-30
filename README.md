## Utool - Quick Server Deployment and Configuration Tool

Utool is a powerful tool support configuring servers, it verry lightweight and providing an efficient and time-saving experience for system administrators

### How to install UTool

```bash
cd && mkdir .utool && cd .utool
curl -L -o utool.tar.gz https://codeload.github.com/leanhthang/server-setup/zip/refs/heads/main
tar -xzf utool.tar.gz -C .utool && rm utool.tar.gz && cd
echo "alias utool='source .utool/utool.sh'" | sudo tee -a ~/.bashrc
source ~/.bashrc
```
