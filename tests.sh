#! /usr/bin/env bash
source shakedown/shakedown.sh

shakedown GET /
  status 200
  content_type "application/openapi+json"

shakedown GET /todos
  status 200
  content_type "application/json"
  matches "\[\]"
