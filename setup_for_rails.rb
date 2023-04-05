menu = %Q(
  ==========================================
                  MENU
  ==========================================
  1. Install dependencies for compiling Ruby
  2. Install lib support image processing
  3. Install PostgreSQL 15
  4. Install MySQL 8
  5. Install Redis
  3. First Setup Server
  4. Add Domain (Nginx/Host)
  5. Add config sidekiq 6/7
  11. test
  Exit (q/quit/exit)
  Select one number:
)
root_path = Dir.pwd

loop do
  puts menu
  input = gets.chomp
  puts "=================== START ===================="
  case input
  when '1'
    system("sh #{root_path}/rails/ubuntu/install_dev_libs.sh")
  when '2'
    system("sh #{root_path}/rails/ubuntu/image_lib.sh")
  when '3'
    system("sh #{root_path}/rails/ubuntu/postgresql.sh")
  when '4'
    system("sh #{root_path}/rails/ubuntu/mysql.sh")
  when '5'
    puts "==> Nhập domain_name:"
    domain_name = gets.chomp
    system("sh #{root_path}/rails/ubuntu/template_nginx.sh #{domain_name}")
  when '11'
    puts "==> Nhập domain_name:"
    domain_name = gets.chomp
    system("sh #{root_path}/rails/ubuntu/test.sh #{domain_name}")
  when 'q', 0, 'quit', 'exit'
    break if input == "q" || input == "quit"
  end
  system("cd #{root_path}")
  puts "=================== END ===================="
  puts ""

  puts "==> Nhập bất kỳ để tiếp tục hoặc q để kết thúc:"
  new_input = gets.chomp
  new_input == 'q' ? break : system("clear")
end
