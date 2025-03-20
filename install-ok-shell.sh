#!/bin/bash

# 定义变量
REPO_URL="https://github.com/ZYZ-Labs/One-Key-Shell.git"
TARGET_DIR="$HOME/.one-key-shell"
SCRIPT_PATH="$TARGET_DIR/ok-shell.c"
INSTALL_PATH="$HOME/.local/bin/ok-shell"

# 检测当前 shell 并设置 SHELL_CONFIG
if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ "$(basename "$SHELL")" = "bash" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    SHELL_CONFIG="$HOME/.profile"
fi

# 拉取仓库
if [ -d "$TARGET_DIR" ]; then
    echo "目录 $TARGET_DIR 已经存在，正在更新..."
    git -C "$TARGET_DIR" pull
else
    echo "正在克隆仓库到 $TARGET_DIR..."
    git clone "$REPO_URL" "$TARGET_DIR"
fi

# 确保 .local/bin 目录存在
mkdir -p "$HOME/.local/bin"

# 编译 C 程序
gcc -o "$INSTALL_PATH" "$SCRIPT_PATH"

# 确保 .local/bin 在 PATH 中
if ! grep -q "$HOME/.local/bin" <<< "$PATH"; then
    echo "export PATH=\$PATH:\$HOME/.local/bin" >> "$SHELL_CONFIG"
fi

if ! grep -q "alias ok-shell=" "$SHELL_CONFIG"; then
    echo "正在添加 ok-shell 命令到 $SHELL_CONFIG..."
    echo "alias ok-shell='$INSTALL_PATH'" >> "$SHELL_CONFIG"
else
    echo "$SHELL_CONFIG 中已经存在 ok-shell 命令"
fi

if ! grep -q "$INSTALL_PATH silent_check_update" "$SHELL_CONFIG"; then
    echo "正在添加自动检查更新命令到 $SHELL_CONFIG..."
    echo "[ -f $INSTALL_PATH ] && $INSTALL_PATH silent_check_update" >> "$SHELL_CONFIG"
fi

echo "安装完成。请重启终端或运行 'source $SHELL_CONFIG' 以使用 ok-shell 命令。"

