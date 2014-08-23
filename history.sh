#!/bin/bash
docker history --no-trunc $1 | sed '1d' | awk '{print $1}' | ./reverse.sh
