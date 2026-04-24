#!/bin/bash

echo "=============================="
echo "  Debian 12 BBR 检测/开启脚本"
echo "=============================="

# 1. 检查内核
kernel=$(uname -r)
echo "[INFO] 当前内核: $kernel"

# 2. 检查当前拥塞控制
cc=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
echo "[INFO] 当前TCP拥塞控制: $cc"

# 3. 检查是否已启用BBR
if [ "$cc" == "bbr" ]; then
    echo "[OK] BBR 已经开启，无需重复操作"
else
    echo "[ACTION] 开始启用 BBR..."

    # 启用 fq
    sysctl -w net.core.default_qdisc=fq

    # 启用 bbr
    sysctl -w net.ipv4.tcp_congestion_control=bbr

    echo "[OK] 已临时开启 BBR"
fi

# 4. 写入永久配置（避免重复）
grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

# 5. 生效
sysctl -p >/dev/null 2>&1

# 6. 再次验证
final=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')

echo "=============================="
echo "[RESULT] 当前最终状态:"
echo "TCP Congestion Control: $final"

if [ "$final" == "bbr" ]; then
    echo "[SUCCESS] BBR 已成功启用"
else
    echo "[WARNING] BBR 未生效，请检查内核支持"
fi

echo "=============================="