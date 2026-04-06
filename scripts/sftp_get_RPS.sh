#!/bin/bash

##############################################################################

#

#   - 从远端 $REMOTE_DIR 拉取所有普通文件到本地 $LOCAL_DIR

#   - 仅 SFTP，可重复执行而不会反复下载相同文件

#   - 远端文件保持原样（不移动 / 不删除）

##############################################################################



REMOTE_DIR="/shared/RPS_response"

LOCAL_DIR="/med/data/RPS/download"

LOG_FILE="/med/data/RPS/downloaded_files.log"

IDENTITY_FILE="prod_sftp_id_rsa"

REMOTE_USER="zsmart_prod"

REMOTE_HOST="183.78.1.11"

REMOTE="${REMOTE_USER}@${REMOTE_HOST}"



# ---------- 0. 本地准备 ----------

cd /med



# ---------- 1. 获取远程文件列表并验证目录 ----------

remote_output=$(sftp -i "$IDENTITY_FILE" -b -
