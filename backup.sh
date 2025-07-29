#!/bin/bash

# 备份目录
HTML_DIR="./html"
BACKUP_DIR="./backup"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 备份 html 目录
HTML_BACKUP_FILE="$BACKUP_DIR/html_backup_$DATE.tar.gz"
tar -czvf "$HTML_BACKUP_FILE" -C "$HTML_DIR" .
echo "已备份 html 目录到 $HTML_BACKUP_FILE"

# 自动查找 _db_data 结尾的卷名
DB_VOLUME_NAME=$(docker volume ls --format '{{.Name}}' | grep '_db_data$' | head -n 1)
if [ -z "$DB_VOLUME_NAME" ]; then
  echo "未找到 _db_data 结尾的 Docker 卷名，备份数据库数据失败。"
  exit 1
fi

# 获取卷的挂载路径
DB_VOLUME_DIR=$(docker volume inspect "$DB_VOLUME_NAME" | grep 'Mountpoint' | awk -F '"' '{print $4}')
if [ ! -d "$DB_VOLUME_DIR" ]; then
  echo "数据库卷目录不存在：$DB_VOLUME_DIR"
  exit 1
fi

# 备份数据库数据卷
DB_BACKUP_FILE="$BACKUP_DIR/db_data_backup_$DATE.tar.gz"
tar -czvf "$DB_BACKUP_FILE" -C "$DB_VOLUME_DIR" .
echo "已备份 $DB_VOLUME_NAME 卷到 $DB_BACKUP_FILE" 