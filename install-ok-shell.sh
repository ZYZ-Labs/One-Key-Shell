#!/bin/bash

# 定义变量
REPO_URL="https://github.com/ZYZ-Labs/One-Key-Shell.git"
TARGET_DIR="$HOME/.one-key-shell"

# 拉取仓库
if [ -d "$TARGET_DIR" ]; then
    echo "目录 $TARGET_DIR 已经存在，正在更新..."
    git -C "$TARGET_DIR" pull
else
    echo "正在克隆仓库到 $TARGET_DIR..."
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# 检测 shell 类型并添加 ok-shell 命令到相应的配置文件
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.profile"
fi

if ! grep -q "alias ok-shell=" "$SHELL_CONFIG"; then
    echo "正在添加 ok-shell 命令到 $SHELL_CONFIG..."
    echo "alias ok-shell='$TARGET_DIR/ok-shell.sh'" >> "$SHELL_CONFIG"
    source "$SHELL_CONFIG"
else
    echo "$SHELL_CONFIG 中已经存在 ok-shell 命令"
fi

echo "安装完成。请重启终端或运行 'source $SHELL_CONFIG' 以使用 ok-shell 命令。"