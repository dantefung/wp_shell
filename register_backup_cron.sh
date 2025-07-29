#!/bin/bash

# ========================
# crontab 配置文件目录说明
#
# 1. 用户级 crontab（推荐用法）
#    每个用户的定时任务通过 crontab -e 编辑，实际存储在：
#      /var/spool/cron/crontabs/<用户名>
#    例如 root 用户：/var/spool/cron/crontabs/root
#    这些文件请勿手动编辑，应通过 crontab 命令管理。
#
# 2. 系统级 crontab
#    全局定时任务配置文件：/etc/crontab
#    可直接编辑，格式比用户 crontab 多一个“用户名”字段：
#      * * * * * root /path/to/command
#
# 3. 定时任务目录
#    系统会定时自动执行以下目录下的脚本：
#      /etc/cron.hourly/
#      /etc/cron.daily/
#      /etc/cron.weekly/
#      /etc/cron.monthly/
#    只需将可执行脚本放入对应目录即可。
#
# 4. 其他
#    /etc/cron.d/ 目录下也可放置自定义 crontab 配置文件，格式同 /etc/crontab。
#
# 总结：
# | 位置                              | 作用                | 备注                      |
# |-----------------------------------|---------------------|---------------------------|
# | /var/spool/cron/crontabs/用户名   | 用户个人定时任务    | 用 crontab 命令管理       |
# | /etc/crontab                      | 系统全局定时任务    | 可直接编辑，需加用户名    |
# | /etc/cron.hourly/ 等目录          | 定时执行目录脚本    | 放可执行脚本即可          |
# | /etc/cron.d/                      | 自定义定时任务文件  | 格式同 /etc/crontab       |
# ========================

# 获取backup.sh的绝对路径
BACKUP_SH_PATH="$(cd "$(dirname "$0")" && pwd)/backup.sh"

# crontab任务内容
# 0 0 1 * * /bin/bash /path/to/backup.sh
# | | | | | |
# | | | | | +---- 一周中的星期几 (0-6, 0代表周日, *代表每天)
# | | | | +------ 月份 (1-12, *代表每月)
# | | | +-------- 一个月中的第几天 (1-31, 1代表每月1日)
# | | +---------- 小时 (0-23, 0代表0点)
# | +------------ 分钟 (0-59, 0代表0分)
# +-------------- crontab时间字段说明
# 该任务表示：每月1日的0点0分执行 backup.sh 脚本
CRON_JOB="0 0 1 * * /bin/bash $BACKUP_SH_PATH"

# 检查crontab中是否已存在该任务
# crontab -l：列出当前用户的所有定时任务
# grep -F "$BACKUP_SH_PATH"：查找是否已有包含 backup.sh 路径的任务
crontab -l 2>/dev/null | grep -F "$BACKUP_SH_PATH" >/dev/null
if [ $? -eq 0 ]; then
  echo "crontab 已存在该备份任务，无需重复添加。"
else
  # 添加任务到crontab
  # (crontab -l; echo "$CRON_JOB") | crontab - ：
  # 先读取已有任务，再追加新任务，然后整体写回 crontab
  # 其中 crontab - 的意思是：让 crontab 从标准输入（stdin）读取新的定时任务内容，
  # 这样可以实现批量更新或追加定时任务。
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
  echo "已添加定时备份任务到crontab：$CRON_JOB"
fi 