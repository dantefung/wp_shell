#!/bin/bash

SETCOLOR_SUCCESS="echo -en \\033[1;32m"

echo "欢迎使用wordpress一键安装脚本"
echo "======================================"
echo "|Author: CollapseEdge                |"
echo "|Modifier: dantefung"
echo "|Email: collapse_edge@outlook.com    |"
echo "|Description: 一键安装wordpress脚本   |"
echo "======================================"

# ========================================
# 第一阶段：系统检测
# ========================================
echo "正在进行系统检测..."
if [[ $EUID -ne 0 ]];then
	echo "请以root账户运行脚本"
	exit 1
else
	echo "系统信息:`uname -v`"
	echo "IP信息:`curl -s myip.ipip.net`"
fi

echo "本程序会安装docker,nginx,mysql,php以及wordpress本体"
echo -n "确认按照(y|n):"
read result

case $result in
	[yY][eE][sS]|[yY])
		# ========================================
		# 第二阶段：安装Docker和Docker Compose
		# ========================================
		echo "=== 开始安装Docker ==="
        sudo apt-get update
		sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker.io
        apt install docker-compose
		
		# ========================================
		# 第三阶段：安装和配置Nginx
		# ========================================
		echo "=== 开始安装Nginx ==="
		sudo apt-get install -y nginx
		
		# ========================================
		# 第四阶段：下载配置文件
		# ========================================
		echo "=== 下载配置文件 ==="
		wget https://raw.githubusercontent.com/dantefung/wp_shell/ver-nginx/docker-compose.yml
        wget https://raw.githubusercontent.com/dantefung/wp_shell/ver-nginx/upload.ini
        wget https://raw.githubusercontent.com/dantefung/wp_shell/ver-nginx/nginx/wordpress.conf
        wget https://raw.githubusercontent.com/dantefung/wp_shell/ver-nginx/nginx_manager.sh
        wget https://raw.githubusercontent.com/dantefung/wp_shell/ver-nginx/recreate_compose.sh
		
		# ========================================
		# 第五阶段：配置Nginx
		# ========================================
		echo "=== 配置Nginx ==="
		# 拷贝wordpress.conf到nginx配置目录
		sudo cp wordpress.conf /etc/nginx/conf.d/
		sudo systemctl reload nginx
		
		# ========================================
		# 第六阶段：启动Docker服务
		# ========================================
		echo "=== 启动Docker服务 ==="
        systemctl start docker.service
        systemctl enable docker
        mkdir html
        docker-compose -f docker-compose.yml up -d
		
		# ========================================
		# 第七阶段：清理临时文件
		# ========================================
		echo "=== 清理临时文件 ==="
		rm -f docker-compose.yml
    	rm -f upload.ini
		rm -f wordpress.conf
		
		# ========================================
		# 安装完成
		# ========================================
		echo -e "\033[32m ---安装成功--- \033[0m" 
		echo "请访问 http://`curl -s ident.me`/wp-admin/install.php"
		echo "并按照指引完成安装"
		echo "如果访问之后出现安装错误的提示,请强制刷新网页"
		;;
	[nN][oO]|[nN])
		echo "no"
		exit 1
		;;
	*)
		echo "Invalid input..."
		exit 1
		;;
esac
