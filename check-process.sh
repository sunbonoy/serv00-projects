#!/bin/bash

log_file="/home/bouray/sh/logfile.log"  # 写入日志文件路径

# 创建日志文件
touch "$log_file"

# 检测进程是否存在的函数
check_process() {
    if pgrep "$1" >/dev/null 2>&1; then
        return 0  # 进程存在
    else
        return 1  # 进程不存在
    fi
}

# 监控进程并重新启动的主要逻辑
processes=("x5" "argo" "web")  # 填入监控的进程名称

for process_name in "${processes[@]}"
do
    check_process "$process_name"

    if [ $? -ne 0 ]; then
        echo "Process $process_name is not running, restarting..."
        # 根据不同的进程执行不同的启动命令
        case "$process_name" in 
        "x5")
        # 启动 xray 的命令
	    nohup /home/bouray/.xray/x5 -c /home/bouray/.xray/config-serv00.json &
	    nohup /home/bouray/.xray/x5 -c /home/bouray/.xray/config-s5.json &
        ;;
        "argo")
        # 启动 cloudflared 的命令
        nohup /home/bouray/.cloudflared/argo tunnel --edge-ip-version auto --protocol http2 --heartbeat-interval 10s run --token eyJhIjoiYzFjZDk0NzY4NjViMzY0MDY2Y2ZjOTFlZTc0NmFjOGIiLCJ0IjoiNmU2NTI3MzQtOTBjZC00YjE2LTg4NjItYzk4ZTFhZTlhNWU5IiwicyI6Ill6RTNPREZqTVdFdE4yTXpNeTAwWVROakxUZzJZbUl0TXpkbE1UUTNORGhpTURSbSJ9 >/dev/null 2>&1 &
        ;;
		"web")
        # 启动 xray 的命令
	    nohup /home/bouray/.hysteria/web server /home/bouray/.hysteria/config.yaml &
	    ;;
        *)
        echo "Unknown process: $process_name"
        ;;
        esac
    	# 输出脚本执行信息到日志文件
    	echo "Process $process_name restarted at $(date)" >> "$log_file"
    else
        echo "Process $process_name is running"
    # 输出脚本执行信息到日志文件
    echo "Process $process_name is running at $(date)" >> "$log_file"
    fi
done
