#!/bin/bash

# 先部署PVC和PV
kubectl apply -f mysqld-pvc.yaml

# 再部署mysql服务
kubectl apply -f ./mysqld-deploy.yaml