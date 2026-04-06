#!/bin/bash



# 配置参数

LOCAL_DIR1="/med/data/RPS/upload"

LOCAL_BAK1="/med/data/RPS/upload/bak"

REMOTE_DIR1="/shared/RPS_request"

LOG_FILE="/med/data/RPS/uploaded_files.log"

IDENTITY_FILE="/med/prod_sftp_id_rsa"

REMOTE_USER="zsmart_prod"

REMOTE_HOST="183.78.1.11"

REMOTE="${REMOTE_USER}@${REMOTE_HOST}"



# 日志记录函数

log() {

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"

}



# 文件上传并备份

process_upload() {

    local src_dir=$1

    local bak_dir=$2

    local remote_dir=$3



    [ -d "$src_dir" ] || { log "源目录不存在: $src_dir"; return 1; }

    mkdir -p "$bak_dir" || { log "无法创建备份目录: $bak_dir"; return 1; }



    local tmp_cmd

    tmp_cmd=$(mktemp) || { log "无法创建临时文件"; return 1; }



    # 构建 sftp 命令文件

    {

        echo "lcd $src_dir"

        echo "cd $remote_dir"

        find "$src_dir" -maxdepth 1 -type f -printf "put \"%P\"\n"

        echo "bye"

    } > "$tmp_cmd"



    # 检查是否有需要上传的文件

    if ! grep -q '^put ' "$tmp_cmd"; then

        log "没有可上传的文件: $src_dir"

        rm -f "$tmp_cmd"

        return 0

    fi



    # 执行上传

    if sftp -i "$IDENTITY_FILE" -b "$tmp_cmd" "$REMOTE" 2>> "$LOG_FILE"; then

        log "上传成功: $src_dir -> $remote_dir"

        find "$src_dir" -maxdepth 1 -type f -exec mv -v {} "$bak_dir" \; >> "$LOG_FILE"

    else

        log "上传失败: $src_dir -> $remote_dir"

        rm -f "$tmp_cmd"

        return 1

    fi



    rm -f "$tmp_cmd"

}



# 主流程

log "========== 开始文件上传任务 =========="



log "处理目录: $LOCAL_DIR1 -> $REMOTE_DIR1"

process_upload "$LOCAL_DIR1" "$LOCAL_BAK1" "$REMOTE_DIR1"





log "========== 文件上传任务结束 =========="



exit 0

