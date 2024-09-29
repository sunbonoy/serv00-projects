#!/bin/bash

USER=$(whoami)
WORKDIR="/home/${USER,,}/sh"
START_SCRIPT="${WORKDIR}/check-process.sh"
CRON_JOB="0 */2 * * * nohup ${START_SCRIPT} >/dev/null 2>&1 &"
LOG_FILE="${WORKDIR}/check.log"

echo "$(date):检查 check-process.sh 文件是否存在，并添加定时任务" | tee -a "$LOG_FILE"

if [ -e "${START_SCRIPT}" ]; then
  echo "$(date): check-process.sh 文件存在，检查 crontab 中是否有相应任务" | tee -a "$LOG_FILE"
  if (crontab -l | grep -F "$START_SCRIPT" > /dev/null); then
    echo "$(date): 定时任务已存在，无需添加。" | tee -a "$LOG_FILE"
  else
    (crontab -l; echo "$CRON_JOB") | crontab -
    echo "$(date): 已添加定时任务：每两小时执行一次 check-process.sh" | tee -a "$LOG_FILE"
  fi
else
  echo "$(date): check-process.sh 文件不存在，未添加任何定时任务" | tee -a "$LOG_FILE"
fi
