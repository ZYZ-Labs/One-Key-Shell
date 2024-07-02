#!/bin/bash

# 读取用户输入的配置文件路径
read -p "请输入配置文件路径: " CONFIG_FILE

# 从文件中读取代理信息
read_proxies() {
  grep "proxy_for" "$CONFIG_FILE" | awk '{print $3}'
}

# 测试代理连通性
test_proxy() {
  local proxy=$1
  echo -n "Testing $proxy... "
  timeout 5 curl -s -o /dev/null --proxy $proxy http://www.google.com
  if [ $? -eq 0 ]; then
    echo "Connected"
  else
    echo "Failed"
  fi
}

# 主函数
main() {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在，请检查路径并重试。"
    exit 1
  fi

  proxies=$(read_proxies)
  for proxy in $proxies; do
    test_proxy $proxy
  done
}

# 运行主函数
main
