# 参考k8s官方文档[《运行一个单实例有状态应用》](https://kubernetes.io/zh-cn/docs/tasks/run-application/run-single-instance-stateful-application/ "《运行一个单实例有状态应用》")使用Minikube部署Mysql8.0

## 1. 部署持久化卷（PersistentVolume）

### 1.1 编写配置文件mysqld-pv.yaml：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### 1.2 部署持久化卷：

```shell
kubectl apply -f mysqld-pv.yaml
```

### 1.3 查看持久化卷声明：

```shell
kubectl describe pvc mysql-pv-claim
```


## 2. 部署Mysql8.0

### 2.1 编写Deployment配置文件mysqld-deploy.yaml：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
  clusterIP: None
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - image: mysql:8.0
        name: mysql
        env:
          # 在实际中使用 secret
        - name: MYSQL_ROOT_PASSWORD
          value: "123456"
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-persistent-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
```

### 2.2 创建Deployment：

```shell
kubectl apply -f mysqld-deploy.yaml
```

### 2.3 查看创建出来的Deployment：

```shell
kubectl describe deployment mysql

Name:               mysql
Namespace:          default
CreationTimestamp:  Tue, 21 Mar 2023 13:52:31 +0800
Labels:             <none>
Annotations:        deployment.kubernetes.io/revision: 1
Selector:           app=mysql
Replicas:           1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:       Recreate
MinReadySeconds:    0
Pod Template:
  Labels:  app=mysql
  Containers:
   mysql:
    Image:      mysql:8.0
    Port:       3306/TCP
    Host Port:  0/TCP
    Environment:
      MYSQL_ROOT_PASSWORD:  123456
    Mounts:
      /var/lib/mysql from mysql-persistent-storage (rw)
  Volumes:
   mysql-persistent-storage:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  mysql-pv-claim
    ReadOnly:   false
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   mysql-84d4db975c (1/1 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  17m   deployment-controller  Scaled up replica set mysql-84d4db975c to 1
```


### 2.4 列出Deployment创建的Pods：

```shell
kubectl get pods -l app=mysql

NAME                     READY   STATUS    RESTARTS   AGE
mysql-84d4db975c-x7n7j   1/1     Running   0          18m
```

查看mysql-84d4db975c-x7n7j这个Pod的详细信息：

```shell
kubectl describe pod mysql-84d4db975c-x7n7j

Name:         mysql-84d4db975c-x7n7j
Namespace:    default
Priority:     0
Node:         minikube/192.168.49.2
Start Time:   Tue, 21 Mar 2023 13:52:31 +0800
Labels:       app=mysql
              pod-template-hash=84d4db975c
Annotations:  <none>
Status:       Running
IP:           172.17.0.3
IPs:
  IP:           172.17.0.3
Controlled By:  ReplicaSet/mysql-84d4db975c
Containers:
  mysql:
    Container ID:   docker://c333a7a1d8df407c04ca61a76674acdaec81f924977bca0bb620aa3b46f06df9
    Image:          mysql:8.0
    Image ID:       docker-pullable://mysql@sha256:2596158f73606ba571e1af29a9c32bec5dc021a2495e4a70d194a9b49664f4d9
    Port:           3306/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 21 Mar 2023 13:53:00 +0800
    Ready:          True
    Restart Count:  0
    Environment:
      MYSQL_ROOT_PASSWORD:  123456
    Mounts:
      /var/lib/mysql from mysql-persistent-storage (rw)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-tfcv2 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  mysql-persistent-storage:
    Type:       PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:  mysql-pv-claim
    ReadOnly:   false
  kube-api-access-tfcv2:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  19m   default-scheduler  Successfully assigned default/mysql-84d4db975c-x7n7j to minikube
  Normal  Pulling    19m   kubelet            Pulling image "mysql:8.0"
  Normal  Pulled     19m   kubelet            Successfully pulled image "mysql:8.0" in 28.433392888s
  Normal  Created    19m   kubelet            Created container mysql
  Normal  Started    19m   kubelet            Started container mysql
```


## 3. 新建一个Pod来访问Mysql8.0实例

```shell
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h mysql -p123456
```
