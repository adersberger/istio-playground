# Istio by Example

## Setting things up (on macOS)

### (1) Install Docker for Mac Edge and enable Kubernetes in settings

### (2) Switch k8s context
```sh
kubectl config use-context docker-for-desktop
```

### (3) Deploy k8s dashboard
 ```sh
 kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
 ```
 
### (4) Extract id of default service account token
```sh
kubectl describe serviceaccount default
```

### (5) Grab token and insert it into k8s Dashboard UI auth dialog
```sh
kubectl describe secret default-token-ID
```

### (6) Start local proxy 
  ```sh
kubectl proxy --port=8001 &

open http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login
```

### (7) Install Istio (will run in namespace istio-system)
 ```sh
 curl -L https://git.io/getLatestIstio | sh -

 export PATH=$PWD/bin:$PATH

 kubectl apply -f istio-*/install/kubernetes/istio.yaml

 kubectl get pods -n istio-system
  ```

### (8) Create Istio sidecar
see: https://istio.io/docs/setup/kubernetes/sidecar-injection.html

 ```sh
./istio-*/install/kubernetes/webhook-create-signed-cert.sh \
--service istio-sidecar-injector \
--namespace istio-system \
--secret sidecar-injector-certs

kubectl apply -f istio-*/install/kubernetes/istio-sidecar-injector-configmap-release.yaml

cat istio-*/install/kubernetes/istio-sidecar-injector.yaml | \
     ./istio-*/install/kubernetes/webhook-patch-ca-bundle.sh > \
     istio-*/install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

kubectl apply -f istio-*/install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml
```

### (9) Label namespace to be auto-sidecared

 ```sh
kubectl label namespace default istio-injection=enabled
kubectl get namespace -L istio-injection
```

## (10) Deploy sample app

```sh
kubectl apply -f istio-*/samples/bookinfo/kube/bookinfo.yaml

#List all ingress endpoints
kubectl describe ingress

open http://localhost/productpage

#BookInfo documentation
open https://istio.io/docs/guides/bookinfo.html
```

... and check that the sidecar container is present within the Pod.

## (11) Deploy Weave Scope

```sh
kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"

kubectl expose deployment weave-scope-app --name=weave-scope-expose --port=4040 --target-port=4040 --type=LoadBalancer -n=weave

open http://localhost:4040
```
