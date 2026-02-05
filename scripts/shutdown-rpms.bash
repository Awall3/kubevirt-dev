#!/bin/bash
# Shutdown the local rpm server (use before building)
docker kill rpms-http-server &> /dev/null
docker rm -f rpms-http-server &> /dev/null