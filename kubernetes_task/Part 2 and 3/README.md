## 1. start your minikube with 2 nodes

```bash
minikube start --nodes 2 -p multinode-demo
```

---

## 2. create 3 namespaces

- The `label` is used for the `mongo-express` namespace to be used `namespaceSelector` part for Network Policy

```bash
kubectl create namespace fe
kubectl create namespace mongo-db
kubectl create namespace mongo-express
---
kubectl label namespace mongo-express app=mongo-express
```

---

## A. Create frontend deployment and service

- Note that the `emptyDir` volume type empties `/usr/share/nginx/html` directory, so we’ll have to add a `.html` file using an `initcontainer`

### Frontend Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: fe
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      initContainers:
      - name: init-web
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
          - echo '<h1>Hello from Nginx Frontend</h1>' > /usr/share/nginx/html/index.html
        volumeMounts:
        - name: cache-volume
          mountPath: /usr/share/nginx/html
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: cache-volume
          mountPath: /usr/share/nginx/html
      volumes:
      - name: cache-volume
        emptyDir:
          sizeLimit: 500Mi
```

### Frontend-Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30008
  selector:
    app: frontend
```

### Exposing Service

```bash
minikube service -n fe frontend-service --url -p multinode-demo
```

![image.png](../attachments/4.png)

---

## B. Deploy a MongoDB database in the mongo-db namespace

- Generating Encoded Secrets
- Note to use `-n` when extracting the secret to avoid adding a new line `\n` in the output

```bash
echo -n admin | base64
echo -n admin123 | base64
```

### Secrets file

- I had to duplicate this secret in the mongo-express namespace, so i can pass these envs in the ConfigMap without hard-coding them

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
type: Opaque
data:
  MONGO_INITDB_ROOT_USERNAME: YWRtaW4= 
  MONGO_INITDB_ROOT_PASSWORD: YWRtaW4xMjM=
```

### PV and PVC

- I made the Storage of the PV and PVC the same, so i don’t have wasted capacity

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mongodb-pv
  namespace: mongo-db
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 500Mi
  hostPath:
    path: /data/db
    
---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  namespace: mongo-db
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

### Mongodb Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
  namespace: mongo-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:latest
        ports:
        - containerPort: 27017
        envFrom:
        - secretRef:
            name: mongodb-secret
        volumeMounts:
        - mountPath: "/data/db"
          name: mongodb-vol
      volumes:
        - name: mongodb-vol
          persistentVolumeClaim:
            claimName: mongodb-pvc
```

### Mongodb Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: mongo-db
spec:
  ports:
    - port: 27017
      targetPort: 27017
  selector:
    app: mongo
```

### Network Policy to allow Pods in the mongo-express namespace only

- Notice the `namespaceSelector` part is used to match the `mongo-epxress` namespace label

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-mongo-express
  namespace: mongo-db
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          app: mongo-express
    ports:
    - protocol: TCP
      port: 27017
```

---

### C. Deploy Mongo Express in mongo-express namespace

### Mongo-express ConfigMap

- Note that Resources in different namespaces can refer to each other by The FQDN of that resource
- So in this example, to refer to the mongodb service, we used its full FQDN `mongodb-service.mongo-db.svc.cluster`
- The FQDN is referenced from **`servicename.namespace.svc.cluster.local`**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongo-express-config
  namespace: mongo-express
data:
  ME_CONFIG_MONGODB_URL: "mongodb://$(MONGO_USERNAME):$(MONGO_PASSWORD)@mongodb-service.mongo-db.svc.cluster.local:27017/"
```

### Mongodb Secret

- Used to pass the user and password for ConfigMap

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-secret
  namespace: mongo-express
type: Opaque
data:
  MONGO_USERNAME: YWRtaW4= 
  MONGO_PASSWORD: YWRtaW4xMjM= 
```

### Mongo-express Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo-express-deployment
  namespace: mongo-express
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo-express
  template:
    metadata:
      labels:
        app: mongo-express
    spec:
      containers:
      - name: mongo-express
        image: mongo-express:latest
        envFrom:
        - configMapRef:
            name: mongo-express-config
        - secretRef:
            name: mongodb-secret
```

### Mongo-express Service file

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongo-express-service
  namespace: mongo-express
spec:
  type: NodePort
  ports:
    - port: 8081
      targetPort: 8081
      nodePort: 30010
  selector:
    app: mongo-express
```

### Expose mongo-express

```bash
minikube service mongo-express-service --url -p multinode-demo -n mongo-express
```

![image.png](../attachments/5.png)

---

## 4. Taint and Toleration

### Taint a node

- This taint a node so that no Pods can be scheduled on it, unless the Pod has a matching toleration

```bash
kubectl taint nodes multinode-demo-m02 app=mongodb:NoSchedule
```

### Apply Toleration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb-deployment
  namespace: mongo-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:latest
        ports:
        - containerPort: 27017
        envFrom:
        - secretRef:
            name: mongodb-secret
        volumeMounts:
        - mountPath: "/data/db"
          name: mongodb-vol
      volumes:
        - name: mongodb-vol
          persistentVolumeClaim:
            claimName: mongodb-pvc
      tolerations:
        - key: "app"
          operator: "Equal"
          value: "mongo"
          effect: "NoSchedule"
```