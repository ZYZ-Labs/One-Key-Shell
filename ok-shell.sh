#!/bin/bash

# 定义变量
TARGET_DIR="$HOME/.one-key-shell/scripts"
REPO_DIR="$HOME/.one-key-shell"

# 静默检查更新
function silent_check_update() {
    git -C "$REPO_DIR" fetch
    LOCAL=$(git -C "$REPO_DIR" rev-parse @)
    REMOTE=$(git -C "$REPO_DIR" rev-parse @{u})

    if [ "$LOCAL" != "$REMOTE" ]; then
        read -p "有可用更新，是否更新？ [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo "正在更新脚本库..."
            git -C "$REPO_DIR" pull
            echo "更新完成。"
        else
            echo "已跳过更新。"
        fi
    fi
}

# 显示帮助信息
function show_help() {
    echo "欢迎使用 One-Key-Shell!"
    echo "可用的命令:"
    echo "  list    - 列出所有可用的脚本"
    echo "  update  - 更新脚本库"
    echo "  help    - 显示此帮助信息"
}

# 更新脚本库
function update_repo() {
    echo "正在更新脚本库..."
    git -C "$REPO_DIR" pull
    echo "更新完成。"
}

# 列出脚本
function list_scripts() {
    echo "可用的脚本:"
    declare -A SCRIPTS
    COUNTER=1
    COUNTER=$(list_scripts_recursive "$TARGET_DIR" "" $COUNTER)

    echo "请输入你想运行的脚本编号: "
    for key in "${!SCRIPTS[@]}"; do
        echo "$key) ${SCRIPTS[$key]}"
    done

    # 询问用户选择的脚本
    read -p "请输入编号: " SCRIPT_NUMBER

    # 执行选择的脚本
    SCRIPT_PATH=${SCRIPTS[$SCRIPT_NUMBER]}
    if [ -f "$SCRIPT_PATH" ]; then
        bash "$SCRIPT_PATH"
    else
        echo "脚本未找到!"
    fi
}

# 递归查找脚本
function list_scripts_recursive() {
    local DIR=$1
    local INDENT=$2
    local COUNTER=$3

    for FILE in "$DIR"/*; do
        if [ -d "$FILE" ]; then
            echo "${INDENT}目录: $(basename "$FILE")"
            COUNTER=$(list_scripts_recursive "$FILE" "  $INDENT" $COUNTER)
        elif [ -f "$FILE" ]; then
            echo "$COUNTER) $INDENT$(basename "$FILE")"
            SCRIPTS[$COUNTER]=$FILE
            ((COUNTER++))
        fi
    done

    echo $COUNTER
}

# 主程序
if [ "$1" == "update" ]; then
    update_repo
elif [ "$1" == "list" ]; then
    list_scripts
elif [ "$1" == "silent_check_update" ]; then
    silent_check_update
else
    silent_check_update
    show_help
fi
