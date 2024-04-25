echo "=== Install Jemalloc ==="
sudo apt-get update
sudo apt-get install libjemalloc2 libjemalloc-dev -y
sudo apt install curl gnupg2 dirmngr -y
echo ''

echo "=== Install Ruby with RBENV ==="

curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
~/.rbenv/bin/rbenv init
eval "$(/root/.rbenv/bin/rbenv init - bash)"
type rbenv

read -p "Enter the ruby version: " ruby_version
echo ''
echo "=== Install Jemalloc for compiling Ruby ==="
# RUBY_CONFIGURE_OPTS=--with-jemalloc asdf install ruby $ruby_version
RUBY_CONFIGURE_OPTS=--with-jemalloc rbenv install $ruby_version
rbenv global $ruby_version
ruby -e "p RbConfig::CONFIG['MAINLIBS']"
which ruby
ruby -v
