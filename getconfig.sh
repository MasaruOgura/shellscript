#!/bin/bash

IFS=$','

while read row; do
  customerlist=(`echo "${row}"`)
  # create directory
  dir=/var/config/aws/${customerlist[3]}; [ ! -e ${dir} ] && sudo mkdir -p ${dir} && sudo chmod 777 ${dir}
  
  # logrotation
  file=${dir}/config
  MAX_LEVEL=6
  MV=mv
  level=${MAX_LEVEL}
  while [ ${level} -gt 1 ]; do
    dst="${file}.${level}.log"
    level=$(expr ${level} - 1)
    src="${file}.${level}.log"
    [ -f "${src}" ] && ${MV} "${src}" "${dst}"
  done
  dst="${file}.1.log"
  src="${file}.log"
  [ -f "${src}" ] && ${MV} "${src}" "${dst}"

  # get configuration
  export AWS_ACCESS_KEY_ID=${customerlist[0]}
  export AWS_SECRET_ACCESS_KEY=${customerlist[1]}
  export AWS_DEFAULT_REGION=${customerlist[2]}
  export AWS_DEFAULT_OUTPUT=text
  /home/ec2-user/command.sh > ${dir}/config.log

  # compare config file
  diff -u ${dir}/config.1.log ${dir}/config.log > ${dir}/diff.log

  # send result to slack
  WEBHOOKURL="https://hooks.slack.com/services/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"
  CHANNEL="#general"
  BOTNAME="diff result"
  FACEICON=":raising_hand:"
  TMPFILE=$(mktemp)
  if [ -s ${dir}/diff.log ]; then
    echo '```' > ${TMPFILE}
    cat ${dir}/diff.log | tr '\n' '\\' | sed 's/\\/\\n/g'>> ${TMPFILE}
    echo '```' >> ${TMPFILE}
  WEBMESSAGE=$(cat ${TMPFILE})
  curl -s -S -X POST --data-urlencode "payload={ \
    \"channel\": \"${CHANNEL}\", \
    \"username\": \"${BOTNAME}\", \
    \"icon_emoji\": \"${FACEICON}\", \
    \"text\": \"${WEBMESSAGE}\" \
    }" ${WEBHOOKURL} >/dev/null
    if [ -f "${TMPFILE}" ] ; then
      rm -f ${TMPFILE}
    fi
  fi
  exit 0
done < customerlist.csv
