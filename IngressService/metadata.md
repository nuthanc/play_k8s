Description:
1. Create a service with 2 pods running nginx
2. Create an ingress out of this service
3. From another pod, do a wget on the Ingress Cluster IP
4. Also validate Ingress get a IP from Public FIP pool and service and its loadbalancing work


vim scripts/k8s_scripts/test_ingress.py
python -m testtools.run scripts.k8s_scripts.test_ingress.TestIngressClusterIp.test_ingress_ip_assignment

```yml
# nginx-svc.yml
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: 2020-03-24T07:27:23Z
  name: ctest-nginx-svc-96546341
  namespace: default
  resourceVersion: "122577"
  selfLink: /api/v1/namespaces/default/services/ctest-nginx-svc-96546341
  uid: e7ac8b0f-6da0-11ea-8c9c-525400010001
spec:
  clusterIP: 10.103.247.85
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: http_test
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}
```

```yml
# nginx-pod
apiVersion: v1
kind: Pod
metadata:
  annotations:
    k8s.v1.cni.cncf.io/network-status: |-
      [
          {
              "ips": "10.47.255.242",
              "mac": "02:f4:c3:3d:96:6d",
              "name": "cluster-wide-default"
          }
      ]
  creationTimestamp: 2020-03-24T07:34:54Z
  labels:
    app: http_test
  name: ctest-nginx-pod-53804551
  namespace: default
  resourceVersion: "123231"
  selfLink: /api/v1/namespaces/default/pods/ctest-nginx-pod-53804551
  uid: f4775342-6da1-11ea-8c9c-525400010001
spec:
  containers:
  - image: nginx
    imagePullPolicy: Always
    name: ctest-nginx-pod-53804551-0
    ports:
    - containerPort: 80
      protocol: TCP
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-75kww
      readOnly: true
  dnsPolicy: ClusterFirst
  nodeName: testbed-1-vm2
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-75kww
    secret:
      defaultMode: 420
      secretName: default-token-75kww
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T07:34:54Z
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T07:35:07Z
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T07:35:07Z
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T07:34:54Z
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: docker://43a907bc2e84f8ad779bae2d674364bd6135e067c36a1d5e56a2be76cb9a63ad
    image: nginx:latest
    imageID: docker-pullable://nginx@sha256:2539d4344dd18e1df02be842ffc435f8e1f699cfc55516e2cf2cb16b7a9aea0b
    lastState: {}
    name: ctest-nginx-pod-53804551-0
    ready: true
    restartCount: 0
    state:
      running:
        startedAt: 2020-03-24T07:35:06Z
  hostIP: 10.204.218.104
  phase: Running
  podIP: 10.47.255.242
  qosClass: BestEffort
  startTime: 2020-03-24T07:34:54Z
```
```
kubectl get pods -o wide
ctest-nginx-pod-53804551   1/1     Running   0          8m54s   10.47.255.242   testbed-1-vm2   <none>
ctest-nginx-pod-70199606   1/1     Running   0          5m20s   10.47.255.241   testbed-1-vm3   <none>

kubectl get ing
NAME                           HOSTS   ADDRESS                        PORTS   AGE
ctest-nginx-ingress-76801795   *       10.204.219.204,10.47.255.240   80      8s
```

```yml
# ingress.yml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  creationTimestamp: 2020-03-24T07:43:17Z
  generation: 1
  name: ctest-nginx-ingress-76801795
  namespace: default
  resourceVersion: "123930"
  selfLink: /apis/extensions/v1beta1/namespaces/default/ingresses/ctest-nginx-ingress-76801795
  uid: 2038dfed-6da3-11ea-8c9c-525400010001
spec:
  backend:
    serviceName: ctest-nginx-svc-96546341
    servicePort: 80
status:
  loadBalancer:
    ingress:
    - ip: 10.204.219.204
    - ip: 10.47.255.240
```

```yml
# Busybox pod
apiVersion: v1
kind: Pod
metadata:
  annotations:
    k8s.v1.cni.cncf.io/network-status: |-
      [
          {
              "ips": "10.47.255.239",
              "mac": "02:a3:5c:8e:36:6d",
              "name": "cluster-wide-default"
          }
      ]
  creationTimestamp: 2020-03-24T08:01:16Z
  name: ctest-busybox-pod-66939990
  namespace: default
  resourceVersion: "125450"
  selfLink: /api/v1/namespaces/default/pods/ctest-busybox-pod-66939990
  uid: a32b30b5-6da5-11ea-8c9c-525400010001
spec:
  containers:
  - command:
    - sleep
    - "1000000"
    image: busybox
    imagePullPolicy: IfNotPresent
    name: ctest-busybox-pod-66939990-0
    resources: {}
    terminationMessagePath: /dev/termination-log
    terminationMessagePolicy: File
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: default-token-75kww
      readOnly: true
  dnsPolicy: ClusterFirst
  nodeName: testbed-1-vm2
  priority: 0
  restartPolicy: Always
  schedulerName: default-scheduler
  securityContext: {}
  serviceAccount: default
  serviceAccountName: default
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
  volumes:
  - name: default-token-75kww
    secret:
      defaultMode: 420
      secretName: default-token-75kww
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T08:01:16Z
    status: "True"
    type: Initialized
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T08:01:23Z
    status: "True"
    type: Ready
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T08:01:23Z
    status: "True"
    type: ContainersReady
  - lastProbeTime: null
    lastTransitionTime: 2020-03-24T08:01:16Z
    status: "True"
    type: PodScheduled
  containerStatuses:
  - containerID: docker://210078c0234a74e7f5a9b96caaddf875dcf964d3ae716bfc453325e03234666c
    image: busybox:latest
    imageID: docker-pullable://busybox@sha256:b26cd013274a657b86e706210ddd5cc1f82f50155791199d29b9e86e935ce135
    lastState: {}
    name: ctest-busybox-pod-66939990-0
    ready: true
    restartCount: 0
    state:
      running:
        startedAt: 2020-03-24T08:01:23Z
  hostIP: 10.204.218.104
  phase: Running
  podIP: 10.47.255.239
  qosClass: BestEffort
  startTime: 2020-03-24T08:01:16Z
  ```