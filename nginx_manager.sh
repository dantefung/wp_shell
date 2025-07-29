#!/bin/bash

set -e

show_menu() {
  echo "==================== Nginx 管理工具 ===================="
  echo "1. 安装 Nginx"
  echo "2. 启动 Nginx"
  echo "3. 停止 Nginx"
  echo "4. 重启 Nginx"
  echo "5. 重载配置（reload）"
  echo "6. 查看状态"
  echo "7. 测试配置语法"
  echo "8. 打开配置目录 (/etc/nginx)"
  echo "9. 显示访问地址"
  echo "10. 拷贝 wordpress.conf 到 conf.d/"
  echo "11. 退出"
  echo "========================================================"
  echo -n "请输入选项 [1-11]: "
}

get_ip() {
  hostname -I | awk '{print $1}'
}

install_nginx() {
  if command -v nginx &> /dev/null; then
    echo "✅ Nginx 已安装"
  else
    echo "📦 正在安装 Nginx..."
    sudo apt update -y
    sudo apt install nginx -y
    echo "🚀 启动并设置开机启动..."
    sudo systemctl start nginx
    sudo systemctl enable nginx
  fi
}

copy_wordpress_conf() {
  if [ ! -f ./wordpress.conf ]; then
    echo "❌ 当前目录下未找到 wordpress.conf 文件！"
    return
  fi

  echo "📁 拷贝 wordpress.conf 到 /etc/nginx/conf.d/"
  sudo cp ./wordpress.conf /etc/nginx/conf.d/wordpress.conf

  echo "🧪 测试配置文件..."
  if sudo nginx -t; then
    echo "✅ 配置正确，正在 reload Nginx..."
    sudo systemctl reload nginx
  else
    echo "❌ 配置文件存在语法错误，请检查 /etc/nginx/conf.d/wordpress.conf"
  fi
}

while true; do
  show_menu
  read -r choice
  case $choice in
    1) install_nginx ;;
    2) sudo systemctl start nginx ;;
    3) sudo systemctl stop nginx ;;
    4) sudo systemctl restart nginx ;;
    5) sudo nginx -s reload || sudo systemctl reload nginx ;;
    6) sudo systemctl status nginx ;;
    7) sudo nginx -t ;;
    8) ls -al /etc/nginx ;;
    9)
      IP=$(get_ip)
      echo "🌐 当前访问地址: http://$IP/"
      ;;
    10) copy_wordpress_conf ;;
    11)
      echo "👋 已退出 Nginx 管理工具。"
      exit 0
      ;;
    *) echo "⚠️ 无效选项，请输入 1-11。" ;;
  esac
  echo ""
  read -p "按回车键继续..." dummy
done

