#!/bin/bash

# 定义文件路径
CONFIG_FILE="$HOME/.domain_port_config"
IPTABLES_CHAIN="DOMAIN_PORT_CHAIN"
CRONTAB_FILE="$HOME/.domain_port_crontab"
SCRIPT_PATH=$(realpath "$0")
UPDATE_INTERVAL="0 * * * *"  # 默认每小时更新一次

# 创建自定义链
initialize_iptables() {
    sudo iptables -N $IPTABLES_CHAIN 2>/dev/null
    sudo iptables -I INPUT -j $IPTABLES_CHAIN 2>/dev/null
}

# 初始化crontab
initialize_crontab() {
    if [ ! -f "$CRONTAB_FILE" ]; then
        echo "$UPDATE_INTERVAL /bin/bash $SCRIPT_PATH update_ips" > "$CRONTAB_FILE"
        crontab "$CRONTAB_FILE"
        echo "已添加定时任务，每小时更新一次 IP 地址。"
    fi
}

# 列出当前配置
list_config() {
    echo "当前配置:"
    if [ -f $CONFIG_FILE ]; then
        cat $CONFIG_FILE
    else
        echo "无配置"
    fi
}

# 新增配置
add_config() {
    read -p "请输入域名: " domain
    read -p "请输入端口: " port
    ip=$(dig +short $domain | tail -n1)

    if [ -z "$ip" ]; then
        echo "无法解析域名 $domain"
        return
    fi

    echo "$domain $port $ip" >> $CONFIG_FILE
    sudo iptables -A $IPTABLES_CHAIN -p tcp --dport $port -s $ip -j ACCEPT
    sudo iptables -A $IPTABLES_CHAIN -p tcp --dport $port -j REJECT
    echo "已添加: $domain:$port -> $ip"
}

# 删除配置
remove_config() {
    read -p "请输入要删除的域名: " domain
    if [ ! -f $CONFIG_FILE ]; then
        echo "无配置"
        return
    fi

    grep -v "^$domain " $CONFIG_FILE > $CONFIG_FILE.tmp
    mv $CONFIG_FILE.tmp $CONFIG_FILE
    echo "已删除域名 $domain 的所有配置"
    reload_iptables
}

# 重新加载iptables规则
reload_iptables() {
    sudo iptables -F $IPTABLES_CHAIN
    while read -r line; do
        domain=$(echo $line | awk '{print $1}')
        port=$(echo $line | awk '{print $2}')
        ip=$(echo $line | awk '{print $3}')
        sudo iptables -A $IPTABLES_CHAIN -p tcp --dport $port -s $ip -j ACCEPT
        sudo iptables -A $IPTABLES_CHAIN -p tcp --dport $port -j REJECT
    done < $CONFIG_FILE
}

# 更新IP地址
update_ips() {
    if [ ! -f $CONFIG_FILE ]; then
        return
    fi

    while read -r line; do
        domain=$(echo $line | awk '{print $1}')
        port=$(echo $line | awk '{print $2}')
        old_ip=$(echo $line | awk '{print $3}')
        new_ip=$(dig +short $domain | tail -n1)

        if [ "$old_ip" != "$new_ip" ]; then
            echo "更新 $domain:$port -> $new_ip"
            sudo iptables -D $IPTABLES_CHAIN -p tcp --dport $port -s $old_ip -j ACCEPT
            sudo iptables -A $IPTABLES_CHAIN -p tcp --dport $port -s $new_ip -j ACCEPT
            sudo iptables -A $IPTABLES_CHAIN -p tcp --dport $port -j REJECT
            sed -i "s/^$domain $port $old_ip$/$domain $port $new_ip/" $CONFIG_FILE
        fi
    done
}

# 修改更新间隔
modify_interval() {
    read -p "请输入新的更新间隔 (如: '0 * * * *' 表示每小时): " new_interval
    UPDATE_INTERVAL=$new_interval
    echo "$UPDATE_INTERVAL /bin/bash $SCRIPT_PATH update_ips" > "$CRONTAB_FILE"
    crontab "$CRONTAB_FILE"
    echo "更新间隔已修改为: $UPDATE_INTERVAL"
}

# 主菜单
main_menu() {
    PS3="请选择操作: "
    options=("列出配置" "新增配置" "删除配置" "修改更新间隔" "退出")
    select opt in "${options[@]}"; do
        case $opt in
            "列出配置")
                list_config
                ;;
            "新增配置")
                add_config
                ;;
            "删除配置")
                remove_config
                ;;
            "修改更新间隔")
                modify_interval
                ;;
            "退出")
                break
                ;;
            *)
                echo "无效选项 $REPLY"
                ;;
        esac
        echo
    done
}

initialize_iptables
initialize_crontab
main_menu
