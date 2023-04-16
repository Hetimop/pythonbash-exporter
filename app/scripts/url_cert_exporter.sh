#!/bin/bash

function get_openssl_output_field {
    local fieldname="$1"
    local openssl_output="$2"
    echo "$openssl_output" | grep "$fieldname" | sed "s/$fieldname=//"
}

# Variable 
URL_FILE="/app/url.list"
URLS=($(cat "$URL_FILE"))

output_script=/tmp/url.tmp
final_file=/tmp/url.metrics
# Supprime le fichier url.metrics s'il existe
rm -f $output_script
touch $output_script

# Parcourt la liste des noms de domaine
for domain in "${URLS[@]}"; do
    url="$domain"
    output=$(timeout 1 openssl s_client -connect "$url" 2> /dev/null | openssl x509 -noout -serial -issuer -subject -dates 2>&1)
    if [[ $output == *"unable to load certificate"* ]]; then
        echo "remote_cert_missing{url=\"$url\"} 1" >> $output_script
    else
        serial=$(get_openssl_output_field 'serial' "$output")
        issuer=$(get_openssl_output_field 'issuer' "$output" | sed 's/"/\\"/g')
        subject=$(get_openssl_output_field 'subject' "$output" | sed 's/"/\\"/g')
        not_before=$(get_openssl_output_field 'notBefore' "$output")
        not_after=$(get_openssl_output_field 'notAfter' "$output")
        remaining_days=$(( ($(date +%s --date="$not_after") - $(date +%s)) / 86400 ))
        echo "remote_cert_info{url=\"$url\",serial=\"$serial\",subject=\"$subject\",issuer=\"$issuer\",not_before=\"$not_before\",not_after=\"$not_after\",days_remaining=\"$remaining_days\"} $remaining_days" >> $output_script
    fi
done

cat $output_script > $final_file
