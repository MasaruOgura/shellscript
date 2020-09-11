#!/bin/bash
# このスクリプトは使用しないことをおすすめします

IFS=$','

# Apacheの1分前のアクセスログを取得
grep `date '+%d/%b/%Y:%H:%M' -d '1 minute ago'` /var/log/httpd/access_log > /home/ec2-user/tmpfile1

# アクセスログからアクセス回数と送信元IPアドレスを抽出
cat /home/ec2-user/tmpfile1 | cut -d " " -f 1 | uniq -c > /home/ec2-user/tmpfile2
sed 's/^[ \t]*//' /home/ec2-user/tmpfile2 > /home/ec2-user/tmpfile3
sed s/\ /,/ /home/ec2-user/tmpfile3 > /home/ec2-user/tmpfile4

# アクセス回数が10回以上ならNACLにDenyのルールを追加する
if [ -s /home/ec2-user/tmpfile4 ];
then

while read row; do
  countlist=(`echo "${row}"`)
  count=${countlist[0]}
  ipaddress=${countlist[1]}
  echo $count
  echo $ipaddress

  if [ $count -gt 10 ];
  then
# 注意)NACLのルールナンバー10に設定されたら、上書きしないので、もうこのスクリプトは機能しません
  aws ec2 create-network-acl-entry --network-acl-id <NACL-id> --ingress --rule-number 10 --protocol -1 --cidr-block ${countlist[1]}/32 --rule-action deny
  fi
done < /home/ec2-user/tmpfile4

else
echo "file is empty."
fi
