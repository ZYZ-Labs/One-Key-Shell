#!/bin/bash

# 检测防火墙类型
detect_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld"
    else
        echo "未知防火墙"
    fi
}

# ufw 操作
ufw_add_temp() {
    read -p "请输入要临时开放的端口: " port
    sudo ufw allow $port
    echo "端口 $port 已临时开放。"
}

ufw_add_perm() {
    read -p "请输入要永久开放的端口: " port
    sudo ufw allow $port
    echo "端口 $port 已永久开放。"
}

ufw_remove() {
    read -p "请输入要移除的端口: " port
    sudo ufw delete allow $port
    echo "端口 $port 已移除。"
}

ufw_list() {
    sudo ufw status numbered
}

# firewalld 操作
firewalld_add_temp() {
    read -p "请输入要临时开放的端口: " port
    sudo firewall-cmd --add-port=$port/tcp
    echo "端口 $port 已临时开放。"
}

firewalld_add_perm() {
    read -p "请输入要永久开放的端口: " port
    sudo firewall-cmd --add-port=$port/tcp --permanent
    sudo firewall-cmd --reload
    echo "端口 $port 已永久开放。"
}

firewalld_remove() {
    read -p "请输入要移除的端口: " port
    sudo firewall-cmd --remove-port=$port/tcp --permanent
    sudo firewall-cmd --reload
    echo "端口 $port 已移除。"
}

firewalld_list() {
    sudo firewall-cmd --list-all
}

# 主菜单
main_menu() {
    local firewall_type=$(detect_firewall)
    echo "检测到的防火墙类型: $firewall_type"
    
    if [ "$firewall_type" == "未知防火墙" ]; then
        echo "不支持的防火墙类型。"
        exit 1
    fi

    PS3="请选择操作: "
    options=("临时添加端口" "永久添加端口" "移除端口" "列出端口" "退出")
    select opt in "${options[@]}"; do
        case $opt in
            "临时添加端口")
                if [ "$firewall_type" == "ufw" ]; then
                    ufw_add_temp
                elif [ "$firewall_type" == "firewalld" ]; then
                    firewalld_add_temp
                fi
                ;;
            "永久添加端口")
                if [ "$firewall_type" == "ufw" ]; then
                    ufw_add_perm
                elif [ "$firewall_type" == "firewalld" ]; then
                    firewalld_add_perm
                fi
                ;;
            "移除端口")
                if [ "$firewall_type" == "ufw" ]; then
                    ufw_remove
                elif [ "$firewall_type" == "firewalld" ]; then
                    firewalld_remove
                fi
                ;;
            "列出端口")
                if [ "$firewall_type" == "ufw" ]; then
                    ufw_list
                elif [ "$firewall_type" == "firewalld" ]; then
                    firewalld_list
                fi
                ;;
            "退出")
                break
                ;;
            *)
                echo "无效选项 $REPLY"
                ;;
        esac
    done
}

main_menu
