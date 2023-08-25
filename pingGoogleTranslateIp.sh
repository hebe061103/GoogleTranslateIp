#!/bin/bash
parm_path=$(cd `dirname $0`; pwd)
cd $parm_path
rm ips.txt
rm activeip.txt
wget --no-check-certificate https://unpkg.com/@hcfy/google-translate-ip/ips.txt  2>&1
#以此往下到下个------------线注释部分为多线程筛选可用节点部分
start_time=`date +%s`  #定义脚本运行的开始时间
success() {
    if ping -c 3 $i >/dev/null        #定义一个函数ping成功一次则显示success
    then
       echo -e "\033[32;1m$i Ping is success\033[0m"
       echo "$i translate.googleapis.com" >> activeip.txt
       echo "$i translate.google.com" >> activeip.txt
    else
       echo -e "\033[31;1m$i Ping is failure\033[0m"
    fi
}
#线程数
thread_num=10
#管道文件名称，这里使用随机数加pid
fifo_file="/tmp/$RANDOM$$.fifo"
mkfifo "$fifo_file"
#定义文件描述符指向这个管道文件
exec 9<>"$fifo_file"
rm -fr "$fifo_file"

#初始化大小
for ((i=0;i<${thread_num};i++));do
    echo
done >&9

for i in `cat ips.txt`
do
read -u9
  {
   success
   sleep 1
} &
echo "">&9
done
wait
stop_time=`date +%s` # 定义脚本运行的结束时间
echo "多线程ping用时:`expr $stop_time - $start_time`s"

echo "# GoogleTranslateIp" > README.md
date=$(date "+%Y-%m-%d %H:%M:%S")
echo "$date 日更新!" >> README.md
if [ -s activeip.txt ]
then
    git init
    git add ./
    git commit -m "$date"
    git branch -M main
    git remote set-url origin https://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@github.com/hebe061103/GoogleTranslateIp.git
    git push -u origin main
fi
