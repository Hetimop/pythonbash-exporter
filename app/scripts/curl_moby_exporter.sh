#!/bin/bash


output_script=/tmp/curl.tmp
final_file=/tmp/curl.metrics
url="https://api.github.com/repos/moby/moby/tags"
rm -f $output_script
touch $output_script

if ! curl --output /dev/null --silent --head --fail "$url"; then
    echo "moby_github_status{url=\"$url\"} 0" >> $output_script

else 
    stable_version=$(curl -s $url | jq '.[].name' | grep -v "-" | head -n 1 | tr -d 'v')
    beta_version=$(curl -s $url | jq '.[].name' | grep "beta" | head -n 1 | tr -d 'v')
    rc_version=$(curl -s $url | jq '.[].name' | grep "rc" | head -n 1 | tr -d 'v')

    echo "moby_github_status{url=\"$url\"} 1" >> $output_script
    echo "moby_docker_engine_version_stable{version=$stable_version} 1" >> $output_script
    echo "moby_docker_engine_version_beta{version=$beta_version} 1" >> $output_script
    echo "moby_docker_engine_version_rc{version=$rc_version} 1" >> $output_script

fi

cat $output_script > $final_file
