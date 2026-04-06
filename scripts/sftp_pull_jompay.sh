#!/bin/bash

##############################################################################

# downloaded_files.log：仅记录已处理的纯文件名

# 脚本逻辑：

# 1. 获取远端 REMOTE_DIR 文件列表

# 2. 对比 downloaded_files.log，未处理文件才下载

# 3. 校验文件（最后一行字段符合规则）

# 4. 校验通过：移动到本地 INPUT_DIR + 记录日志 + rename 到远端 DONE_DIR

##############################################################################



REMOTE_DIR="/shared/jompay_input"

DONE_DIR="/shared/jompay_input/done"



LOCAL_TMP_DIR="/med/data/SFTP/tmp"

LOCAL_INPUT_DIR="/med/data/SFTP/input"



LOG_FILE="/med/data/SFTP/downloaded_files.log"

PROCESSED_MARKER="$LOG_FILE"



IDENTITY_FILE="prod_sftp_id_rsa"

REMOTE_USER="zsmart_prod"

REMOTE_HOST="183.78.1.11"

REMOTE="${REMOTE_USER}@${REMOTE_HOST}"



SFTP_LIST_TMP="/tmp/sftp_file_list_$(date +%s).tmp"



# 初始化目录和日志

cd /med || exit 1

mkdir -p "$LOCAL_TMP_DIR" "$LOCAL_INPUT_DIR"

touch "$LOG_FILE"



echo "[$(date '+%F %T')] 获取远端文件列表..."

sftp -i "$IDENTITY_FILE" -q "$REMOTE" <<EOF > "$SFTP_LIST_TMP"

cd "$REMOTE_DIR"

ls -l

EOF



[ ! -s "$SFTP_LIST_TMP" ] && echo "[$(date '+%F %T')] 无远端文件" && exit 0



# 提取文件名（只保留普通文件，排除目录）

remote_files=$(awk '$1 ~ /^-/{print $NF}' "$SFTP_LIST_TMP")

rm -f "$SFTP_LIST_TMP"



echo "$remote_files" | while read -r file; do

    [ -z "$file" ] && continue



    # 已处理文件跳过

    if grep -Fxq "$file" "$PROCESSED_MARKER"; then

        echo "[$(date '+%F %T')] 已处理，跳过：$file"

        continue

    fi



    local_file="$LOCAL_TMP_DIR/$file"

    echo "[$(date '+%F %T')] 处理文件：$file"



    # 下载文件

    if ! sftp -i "$IDENTITY_FILE" -q "$REMOTE" <<EOF > /dev/null 2>&1; then

cd "$REMOTE_DIR"

lcd "$LOCAL_TMP_DIR"

get "$file" "$local_file"

EOF

        echo "[$(date '+%F %T')] 下载失败：$file"

        rm -f "$local_file"

        continue

    fi



    # 检查文件存在且非空

    if [ ! -f "$local_file" ] || [ ! -s "$local_file" ]; then

        echo "[$(date '+%F %T')] 下载后文件不存在或为空：$file"

        rm -f "$local_file"

        continue

    fi



    # 校验最后一行

    total_lines=$(wc -l < "$local_file" | tr -d ' \r')

    last_col1=$(tail -1 "$local_file" | awk '{print $1}' | tr -d '\r')

    last_col2=$(tail -1 "$local_file" | awk '{print $2}' | tr -d '\r')



    if [[ "$last_col1" =~ ^[0-9]+$ && "$last_col2" =~ ^[0-9]+$ ]] && \

       [ "$last_col1" -eq 9 ] && [ "$last_col2" -eq "$total_lines" ]; then

        # 校验通过

        mv "$local_file" "$LOCAL_INPUT_DIR/" && echo "$file" >> "$LOG_FILE"

        echo "[$(date '+%F %T')] 校验通过：$file"



        # 远端移动到 DONE_DIR

        if ! sftp -i "$IDENTITY_FILE" -q "$REMOTE" <<EOF > /dev/null 2>&1; then

cd "$REMOTE_DIR"

rename "$file" "$DONE_DIR/$file"

EOF

            echo "[$(date '+%F %T')] ⚠️ ERROR: 远端 rename 失败：$file" >&2

        fi

    else

        # 校验失败

        echo "[$(date '+%F %T')] 校验失败：$file"

        rm -f "$local_file"

    fi

done



echo "[$(date '+%F %T')] 处理完成"

exit 0
