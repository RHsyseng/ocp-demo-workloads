#!/bin/sh

oc new project duckhunt --skip-config-write=true
oc new-app nodeshift/centos7-s2i-nodejs:12.x~https://github.com/vrutkovs/DuckHunt-JS -n duckhunt
oc expose svc/duckhunt-js -n duckhunt
