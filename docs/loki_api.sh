#!/bin/bash



uat_url=''
job_name=''
#error=$(echo -e 'Got\[\[\:space\:\]\]ping')
error='ERROR'
ERROR=''
date=$(date +%Y-%m-%d)
for j in $job_name
do
    job='query={job="'"${j}"'"}|~"'"${error}"'"'
    result=`curl -G -s  "http://localhost:port/loki/api/v1/query_range" --data-urlencode $job | jq '.data.result'`
    if [ "$result" != "[]" ]
    then
        result=`echo $result | jq '.[0].values[:6]'`
        for i in `seq 0 5`
        do
            result_line=$(echo $(echo $result |jq '.['${i}'][-1]')|sed 's/\"//g')
            result_lines+=$result_line
        done
        result_lines=`echo $result_lines |sed "s/${date}/\n${date}/g"`
        # curl $uat_url -H 'Content-Type: application/json' \
        #    -d '{
        #         "msgtype": "markdown",
        #         "markdown": {
        #           "content": "
        #         项目名称: '"$j"'
        #         错误日志:'"$result_lines"'
        #           "
        #         }
        #      }'   
    fi
done
