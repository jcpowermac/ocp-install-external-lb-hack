
#!/bin/bash


USERNAME=dataplaneapi
PASSWORD=dataplaneapi


MASTER_BACKENDS=("api-server" "machine-config-server")
INGRESS_BACKENDS=("router-http" "router-https")

MASTER_SUBNETS=("192.168.11.0/24" "192.168.12.0/24" "192.168.13.0/24")
INGRESS_SUBNETS=("192.168.11.0/24" "192.168.12.0/24" "192.168.13.0/24")


CONFIG_VERSION=$(http "http://127.0.0.1:5555/v2/services/haproxy/configuration/version" -p b --auth "${USERNAME}:${PASSWORD}")

TRANSACTION=$(http POST "http://127.0.0.1:5555/v2/services/haproxy/transactions?version=${CONFIG_VERSION}" -p b --auth "${USERNAME}:${PASSWORD}")

TRANSACTION_ID=$(echo "${TRANSACTION}" | jq -r '.id')


 
for mbackend in "${MASTER_BACKENDS[@]}"
do
	JSON=$(http -p b --auth "${USERNAME}:${PASSWORD}" "http://127.0.0.1:5555/v2/services/haproxy/configuration/servers?backend=${mbackend}")
	SERVER_NAMES=$(echo "${JSON}" | jq -r '.data[] | .name')
	readarray -t <<< "${SERVER_NAMES}"

        for s in "${MAPFILE[@]}"
	do
		http DELETE "http://127.0.0.1:5555/v2/services/haproxy/configuration/servers/${s}" backend=="${mbackend}" transaction_id=="${TRANSACTION_ID}" --auth "${USERNAME}:${PASSWORD}"
	done
done

http PUT "http://127.0.0.1:5555/v2/services/haproxy/transactions/${TRANSACTION_ID}" --auth "${USERNAME}:${PASSWORD}" 


#http --auth ${USERNAME}:${PASSWORD} http://127.0.0.1:5555/v2/services/haproxy/configuration/servers\?backend\=api-server

                #http --auth ${USERNAME}:${PASSWORD} http://127.0.0.1:5555/v2/services/haproxy/configuration/servers\?backend\=api-server

