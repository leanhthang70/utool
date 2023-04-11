echo "=== Install Jemalloc ==="
sudo apt-get update
sudo apt-get install libjemalloc2 libjemalloc-dev -y
sudo apt install curl gnupg2 dirmngr -y
echo ''
echo "=== Install Ruby with RBENV ==="
echo ''
asdf plugin add ruby
echo ''
echo -n "Nhập vào phiên bản ruby cần cài:  "
echo ''
read ruby_version
RUBY_CONFIGURE_OPTS=--with-jemalloc asdf install ruby $ruby_version
ruby -e "p RbConfig::CONFIG['MAINLIBS']"
asdf global ruby $ruby_version
which ruby
ruby -v
