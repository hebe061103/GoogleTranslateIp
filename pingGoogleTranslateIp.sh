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
    while true;
    do
    git init
    git add ./
    git commit -m "$date"
    git branch -M main
    git remote set-url origin https://$GITHUBTOKEN@github.com/hebe061103/GoogleTranslateIp.git
    result=`git push -u origin main`
    if echo "$result" | grep -e "set up to track remote branch";then
       date=$(date "+%Y-%m-%d %H:%M:%S")
       echo --$date-- "------------------------同步到github成功-------------------------" |tee -a /tmp/pingGoogleTranslateIp.log
       break
    else
       let try_num++
       date=$(date "+%Y-%m-%d %H:%M:%S")
       echo --$date-- "------------------------同步失败,执行第$try_num次尝试-------------------------" |tee -a /tmp/pingGoogleTranslateIp.log
       sleep 30
       if [ $try_num -eq 10 ];then
           echo --$date-- "------------------------经过$try_num次尝试依然失败,故障退出-------------------------" |tee -a /tmp/pingGoogleTranslateIp.log
           break
       fi
    fi
    done
fi
#清除日志内容
a=$(grep -c "" /tmp/pingGoogleTranslateIp.log)
if [ $a -gt 200 ]; then
    rm /tmp/pingGoogleTranslateIp.log
fi
