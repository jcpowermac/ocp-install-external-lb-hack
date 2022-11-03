
#!/bin/bash


USERNAME=dataplaneapi
PASSWORD=dataplaneapi


MASTER_BACKENDS=("api-server" "machine-config-server")
INGRESS_BACKENDS=("router-http" "router-https")

MASTER_SUBNETS=("192.168.20.0/24" "192.168.12.0/24" "192.168.13.0/24")
INGRESS_SUBNETS=("192.168.23.0/24" "192.168.24.0/24")

declare -A portmap

portmap[api-server]=6443
portmap[machine-config-server]=22623
portmap[router-http]=80 
portmap[router-https]=443 

CONFIG_VERSION=$(http "http://127.0.0.1:5555/v2/services/haproxy/configuration/version" -p b --auth "${USERNAME}:${PASSWORD}")

TRANSACTION=$(http POST "http://127.0.0.1:5555/v2/services/haproxy/transactions?version=${CONFIG_VERSION}" -p b --auth "${USERNAME}:${PASSWORD}")

TRANSACTION_ID=$(echo "${TRANSACTION}" | jq -r '.id')
DATA='{"address":"1.1.1.1","check":"enabled","check-ssl":"enabled","name":"temp","port": 443}'
 
for msubnet in "${INGRESS_SUBNETS[@]}"
do

        MINADDR=$(ipcalc -j "${msubnet}" |jq -r '.MINADDR' | awk -F. '{print $4}')

        MAXADDR=$(ipcalc -j "${msubnet}" |jq -r '.MAXADDR' | awk -F. '{print $4}')
	TEMP_NETWORK=$(ipcalc -j  "${msubnet}" | jq -r '.NETWORK')

	NETWORK=${TEMP_NETWORK::-1}
	THIRD_OCTET=$(echo "${TEMP_NETWORK}" | awk -F. '{print $3}')

        IPSEQ=$(seq "${MINADDR}" "${MAXADDR}")

        for mbackend in "${INGRESS_BACKENDS[@]}"
        do
                for ip in `seq "${MINADDR}" "${MAXADDR}"` 
                do

			TEMP_NEW_BACKEND=$(echo "${DATA}" | jq -r --arg name "ingress-${THIRD_OCTET}-${ip}" --arg ip "${NETWORK}${ip}" '.address = $ip | .name = $name')
			NEW_BACKEND=$(echo "${TEMP_NEW_BACKEND}" | jq -r --argjson port "${portmap[$mbackend]}" '.port = $port')


			echo -n ${NEW_BACKEND} | http "http://127.0.0.1:5555/v2/services/haproxy/configuration/servers" backend=="${mbackend}" transaction_id=="${TRANSACTION_ID}" --auth "${USERNAME}:${PASSWORD}" 
                done
        done
done

http PUT "http://127.0.0.1:5555/v2/services/haproxy/transactions/${TRANSACTION_ID}" --auth "${USERNAME}:${PASSWORD}" 

