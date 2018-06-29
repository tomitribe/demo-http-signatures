#!/bin/bash

function post {
curl -v \
 --header "Content-Type: application/json" \
 --header 'accept: application/json' \
 --header 'authorization: Basic YWRtaW46YWRtaW4=' \
 --header 'cache-control: no-cache' \
 -X POST -d @$1 \
 $2
}

post data/kenny-mccormick.json http://localhost:8080/tag/api/account
post data/eric-cartman.json http://localhost:8080/tag/api/account
post data/route_osx.json http://localhost:8080/tag/api/route
