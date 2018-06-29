#!/bin/bash

while [[ $# > 1 ]]
do
key="$1"

case $key in
  -k|--key)
  KEY_ALIAS="$2"
  shift # past argument
  ;;
  -s|--secret)
  SECRET="$2"
  shift # past argument
  ;;
  -X)
  VERB="$2"
  shift # past argument
  ;;
  -t|--content-type)
  CONTENT_TYPE="$2"
  shift # past argument
  ;;
  -d|--data)
  DATA="$2"
  shift # past argument
  ;;
  *)
          # unknown option
  ;;
esac
shift # past argument or value
done

if [[ -n $1 ]]; then
    URL=$1;
fi

if [ -z "$KEY_ALIAS" ] || [ -z "$SECRET" ] || [ -z "$URL" ]; then
  echo "Usage: sign.sh --key <key alias> --secret <shared secret> [-X <HTTP Verb>] [--data <payload>] <url>";
  exit 1;
fi

if [ -z "$VERB" ]; then
  if [ -z "$DATA" ]; then
    DATA=""
    VERB="GET"
  else
    VERB="POST"
  fi
fi

if [ -z "$CONTENT_TYPE" ]; then
  $CONTENT_TYPE="application/x-www-form-urlencoded"
fi

# extract the protocol
PROTO="`echo $URL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
# remove the protocol
REMAINDER=`echo $URL | sed -e s,$PROTO,,g`

# extract the user and password (if any)
USERPASS="`echo $REMAINDER | grep @ | cut -d@ -f1`"
PASS=`echo $USERPASS | grep : | cut -d: -f2`
if [ -n "$PASS" ]; then
  USER=`echo $USERPASS | grep : | cut -d: -f1`
else
  USER=$USERPASS
fi

# extract the host -- updated
HOSTPORT=`echo $REMAINDER | sed -e s,$USERPASS@,,g | cut -d/ -f1`
PORT=`echo HOSTPORT | grep : | cut -d: -f2`
if [ -n "$PORT" ]; then
  HOST=`echo $HOSTPORT | grep : | cut -d: -f1`
else
  HOST=$HOSTPORT
fi

# extract the path (if any)
URL_PATH="`echo $REMAINDER | grep / | cut -d/ -f2-`"

LC_VERB=`echo "${VERB}" | tr '[:upper:]' '[:lower:]'`
SIGNING_STRING="(request-target): ${LC_VERB} /${URL_PATH}"

echo SIGNING_STRING = "
${SIGNING_STRING}"

SIGNATURE=`echo -n "${SIGNING_STRING}" | openssl dgst -binary -sha256 -hmac "${SECRET}" | base64`

SIGNATURE_HEADER="Signature keyId=\"${KEY_ALIAS}\",algorithm=\"hmac-sha256\",headers=\"(request-target)\",signature=\"${SIGNATURE}\""
echo SIGNATURE_HEADER = "
${SIGNATURE_HEADER}"

curl -v -X ${VERB} -H "Authorization:${SIGNATURE_HEADER}" -H "Content-Type:${CONTENT_TYPE}" ${URL} -d "${DATA}" --insecure
