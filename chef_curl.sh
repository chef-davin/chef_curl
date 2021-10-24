#!/bin/bash

# set some defaults if you don't want to use a lot of the command options

CHEF_SERVER_URL="https://my.chef.server"
CHEF_USER_NAME="pivotal"
CHEF_USER_PEM="/etc/chef/pivotal.pem"
CHEF_CLIENT_VERSION="17.6.18"
CACERT_PATH="/opt/chef/embedded/ssl/certs/cacert.pem"
REST_METHOD="GET"
REST_BODY=""

usage () {
  echo "chef_curl [options] API_PATH"
  echo -e "Options:"
  echo -e "\t-h: Display this help message"
  echo -e "\t-s: Chef Server URL"
  echo -e "\t-u: Chef user name"
  echo -e "\t-p: Chef User PEM file path"
  echo -e "\t-c: CACert Path (defaults to /etc/chef/embedded/ssl/certs/cacert.pem)"
  echo -e "\t-v: Chef client version declaration (defaults to 17.6.18)"
  echo -e "\t-X: REST Method to use (i.e. GET, PUT, POST). Defaults to GET"
  echo -e "\t-d: REST message body (used with POST and PUT methods)"
}

while getopts ":hs:u:p:c:v:X:d:" opt; do
  case ${opt} in
    h ) usage; exit 0
      ;;
    s ) CHEF_SERVER_URL=$OPTARG
      ;;
    u ) CHEF_USER_NAME=$OPTARG
      ;;
    p ) CHEF_USER_PEM=$OPTARG
      ;;
    c ) CACERT_PATH=$OPTARG
      ;;
    v ) CHEF_CLIENT_VERSION=$OPTARG
      ;;
    X ) REST_METHOD=$OPTARG
      ;;
    d ) REST_BODY=$OPTARG
      ;;
    \? ) usage; exit 1
      ;;
  esac
done
shift $((OPTIND -1))

SERVER_PATH=${1%%\?*}

_chomp () {
  # helper function to remove newlines
  awk '{printf "%s", $0}'
}

build_headers() {
  PATH_HASH=$(echo -n "$SERVER_PATH" | openssl dgst -sha1 -binary | openssl enc -base64)
  BODY_HASH=$(echo -n "$REST_BODY" | openssl dgst -sha1 -binary | openssl enc -base64)
  TIMESTAMP=$(date -u "+%Y-%m-%dT%H:%M:%SZ")

  CANONICAL="\
Method:${REST_METHOD}\n\
Hashed Path:${PATH_HASH}\n\
X-Ops-Content-Hash:${BODY_HASH}\n\
X-Ops-Timestamp:${TIMESTAMP}\n\
X-Ops-UserId:${CHEF_USER_NAME}"

  HEADERS="\
-H X-Ops-Timestamp:${TIMESTAMP} \
-H X-Ops-Userid:$CHEF_USER_NAME \
-H X-Chef-Version:$CHEF_CLIENT_VERSION \
-H Accept:application/json \
-H X-Ops-Content-Hash:${BODY_HASH} \
-H X-Ops-Sign:version=1.0 \
-H Content-Type:application/json"

  AUTH_HEADERS=$(printf "${CANONICAL}" | openssl rsautl -sign -inkey \
    "${CHEF_USER_PEM}" | openssl enc -base64 | _chomp |  awk '{ll=int(length/60);i=0; \
    while (i<=ll) {printf " -H X-Ops-Authorization-%s:%s", i+1, substr($0,i*60+1,60);i=i+1}}')
}


chef_api_request() {
  build_headers

  URL="${CHEF_SERVER_URL}${SERVER_PATH}"

  if [ -z "${REST_BODY}" ]
  then
    # echo "curl -v -s -X ${REST_METHOD} --cacert ${CACERT_PATH} ${HEADERS} ${AUTH_HEADERS} ${URL}"
    eval "curl -s -X ${REST_METHOD} --cacert ${CACERT_PATH} ${HEADERS} ${AUTH_HEADERS} ${URL} | jq"
  else
    # echo "curl -v -s -X ${REST_METHOD} --cacert ${CACERT_PATH} ${HEADERS} ${AUTH_HEADERS} ${URL} -d '${REST_BODY}'"
    eval "curl -s -X ${REST_METHOD} --cacert ${CACERT_PATH} ${HEADERS} ${AUTH_HEADERS} ${URL} -d '${REST_BODY}' | jq"
  fi
}

chef_api_request "$@"
