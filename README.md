## Utool - Quick Server Deployment and Configuration Tool

Utool is a powerful tool support configuring servers, it verry lightweight and providing an efficient and time-saving experience for system administrators

### How to install UTool

```bash
cd && curl -O https://raw.githubusercontent.com/leanhthang/server-setup/main/build_utool && bash build_utool v0.0.2
```

### How to remove UTool

```bash
cd && rm -rf .utool
# open ~/.bashrc remove line below
alias utool='source $HOME/.utool/utool.sh'
```
### How to use

```bash
utool
```
