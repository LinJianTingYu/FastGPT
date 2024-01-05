#!/bin/bash

# fastgpt2
# docker -H tcp://192.168.1.3:2375 build -t fastgpt --build-arg name=app --build-arg proxy=taobao .
# docker -H tcp://192.168.1.3:2375 kill fastgpt2
# docker -H tcp://192.168.1.3:2375 rm fastgpt2
# docker -H tcp://192.168.1.3:2375 run -d -p 3002:3000 --name fastgpt2 fastgpt

# fastgpt
docker -H tcp://192.168.1.3:2375 build -t fastgpt --build-arg name=app --build-arg proxy=taobao .
docker -H tcp://192.168.1.3:2375 kill fastgpt
docker -H tcp://192.168.1.3:2375 rm fastgpt
docker -H tcp://192.168.1.3:2375 run -d -p 3001:3000 --name fastgpt fastgpt
