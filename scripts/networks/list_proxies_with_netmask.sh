#!/bin/bash

# 读取用户输入的配置文件路径
read -p "请输入配置文件路径: " CONFIG_FILE

# 从文件中读取代理信息
read_proxies() {
  grep "proxy_for" "$CONFIG_FILE" | awk '{print $3}'
}

# 将 IP 地址添加子网掩码
add_netmask() {
  local ip=$1
  echo "$ip/32"
}

# 主函数
main() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在，请检查路径并重试。"
    exit 1
  fi

  proxies=$(read_proxies)
  for proxy in $proxies; do
    netmask_ip=$(add_netmask $proxy)
    echo "$netmask_ip"
  done
}

# 运行主函数
main
