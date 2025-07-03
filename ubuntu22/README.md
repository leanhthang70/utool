# Ubuntu 22 Development Environment Setup

## 📋 Tổng quan

Phiên bản cải tiến của bộ công cụ thiết lập môi trường phát triển cho Ubuntu 22.04 với các tính năng nâng cao:

- ✅ Xử lý lỗi và validation đầu vào tốt hơn
- ✅ Hệ thống logging toàn diện
- ✅ Quản lý cấu hình linh hoạt
- ✅ Backup tự động
- ✅ Bảo mật được cải thiện
- ✅ Giao diện người dùng thân thiện

## 🚀 Cách sử dụng

### Chạy script chính

```bash
chmod +x ubuntu22/main.sh
./ubuntu22/main.sh
```

### Chạy script riêng lẻ

```bash
# Docker (Enhanced)
chmod +x ubuntu22/docker.sh
./ubuntu22/docker.sh

# Nginx SSL (Enhanced)
chmod +x ubuntu22/nginx_ssl.sh
./ubuntu22/nginx_ssl.sh

# MySQL (Enhanced)
chmod +x ubuntu22/mysql.sh
./ubuntu22/mysql.sh
```

## 📁 Cấu trúc files

### Files gốc (Original)

- `auto_after_reboot.sh` - Tạo service tự động chạy sau reboot
- `capostrano_rails_puma.sh` - Cấu hình Puma Rails server
- `docker.sh` - Cài đặt Docker cơ bản
- `image_lib.sh` - Cài đặt thư viện xử lý hình ảnh
- `install_common_dev_libs.sh` - Cài đặt thư viện phát triển
- `logrotate.sh` - Cấu hình log rotation
- `mysql.sh` - Quản lý MySQL/MariaDB cơ bản
- `nginx_ssl.sh` - Cài đặt Nginx với SSL cơ bản
- `postgresql.sh` - Quản lý PostgreSQL
- `rails_setup.sh` - Cài đặt Ruby on Rails
- `sidekiq.sh` - Cấu hình Sidekiq background jobs
- `user.sh` - Quản lý user

### Files đã cải tiến

- `common.sh` - Thư viện functions chung
- `config.conf` - File cấu hình
- `main.sh` - Script chính cải tiến
- `docker.sh` - Docker cài đặt cải tiến
- `nginx_ssl.sh` - Nginx SSL cải tiến
- `mysql.sh` - MySQL/MariaDB cải tiến

## 🔧 Tính năng cải tiến

### 1. Xử lý lỗi và Validation

- Kiểm tra đầu vào người dùng
- Validation domain, email, IP address
- Kiểm tra file/directory tồn tại
- Xử lý lỗi graceful

### 2. Hệ thống Logging

- Log với timestamp và level
- Log ra console và file
- Phân loại log: ERROR, WARN, INFO, DEBUG
- File log: `/var/log/utool/utool.log`

### 3. Quản lý Cấu hình

- File cấu hình tập trung: `config.conf`
- Giá trị mặc định có thể tùy chỉnh
- Backup cấu hình trước khi thay đổi

### 4. Backup & Restore

- Backup tự động trước khi cài đặt
- Thư mục backup: `/opt/backups/`
- Backup cấu hình hệ thống
- Quản lý backup database

### 5. Bảo mật

- Cấu hình SSL/TLS tối ưu
- Security headers cho Nginx
- Firewall configuration
- Strong password policies

### 6. Giao diện người dùng

- Menu tương tác
- Progress indicators
- Color-coded output
- Help và documentation

## 📊 Cấu hình mặc định

```bash
# User settings
DEFAULT_USER="deploy"
DEFAULT_NODE_VERSION="18.x"
DEFAULT_RUBY_VERSION="3.1.0"

# Database settings
DEFAULT_MYSQL_PORT="3306"
DB_CHARSET="utf8mb4"
DB_COLLATION="utf8mb4_general_ci"

# Backup settings
BACKUP_DIR="/opt/backups"
LOG_DIR="/var/log/utool"

# Security settings
ENABLE_FIREWALL="true"
BACKUP_BEFORE_INSTALL="true"
VALIDATE_INPUTS="true"
```

## 🛠️ Troubleshooting

### 1. Kiểm tra logs

```bash
tail -f /var/log/utool/utool.log
```

### 2. Kiểm tra services

```bash
systemctl status nginx
systemctl status mysql
systemctl status docker
```

### 3. Kiểm tra cấu hình

```bash
nginx -t
mysql -u root -p -e "SHOW DATABASES;"
docker info
```

### 4. Backup recovery

```bash
ls -la /opt/backups/
```

## 🔐 Bảo mật

### SSL/TLS Configuration

- TLS 1.2 và 1.3 only
- Strong cipher suites
- HSTS headers
- SSL stapling

### Database Security

- Strong password requirements
- Limited user privileges
- Remote access controls
- Regular security updates

### System Security

- Firewall configuration
- Service hardening
- Log monitoring
- Regular backups

## 📚 Tài liệu tham khảo

### Scripts gốc

- Functionality cơ bản
- Interactive prompts
- Basic error handling

### Scripts cải tiến

- Advanced error handling
- Comprehensive logging
- Configuration management
- Security best practices
- User experience improvements

## 🤝 Đóng góp

Để cải tiến thêm các scripts:

1. Sử dụng functions từ `common.sh`
2. Implement proper error handling
3. Add logging cho tất cả operations
4. Validate user inputs
5. Backup trước khi thay đổi
6. Test thoroughly
7. Update documentation

## 📝 Changelog

### Version 2.0 (Enhanced)

- ✅ Added comprehensive error handling
- ✅ Implemented logging system
- ✅ Created configuration management
- ✅ Added backup functionality
- ✅ Improved security configurations
- ✅ Enhanced user interface
- ✅ Added system monitoring
- ✅ Improved documentation

### Version 1.0 (Original)

- ✅ Basic installation scripts
- ✅ Interactive prompts
- ✅ Service configuration
- ✅ Database management

## 📞 Hỗ trợ

- Kiểm tra logs: `/var/log/utool/utool.log`
- Backup location: `/opt/backups/`
- Configuration: `ubuntu22/config.conf`
- Help command: Option 16 trong main menu
