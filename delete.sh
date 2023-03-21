#!/bin/bash

kubectl delete deployment mysql
kubectl delete svc mysql
kubectl delete pvc mysql-pv-claim
kubectl delete pv mysql-pv-volume