# Istio by Example

## (0) Open current environment
```sh
kubectl proxy --port=8001 &
#Application endpoint
open http://localhost/productpage
#Kubernetes Dashboard
open http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login
#Weave Scope
open http://localhost:4040
```

## (1) Diagnosability: Metrics

### Install and expose Prometheus and Grafana

```sh
#Prometheus
kubectl apply -f istio-*/install/kubernetes/addons/prometheus.yaml
kubectl expose deployment prometheus --name=prometheus-expose --port=9090 --target-port=9090 --type=LoadBalancer -n=istio-system
open http://localhost:9090/graph?g0.range_input=1h&g0.expr=istio_double_request_count&g0.tab=0

#Grafana
kubectl apply -f istio-*/install/kubernetes/addons/grafana.yaml
kubectl expose deployment grafana --name=grafana-expose --port=3000 --target-port=3000 --type=LoadBalancer -n=istio-system
open http://localhost:3000/d/1/istio-dashboard
```

### Deploy Istio telemetry definition

```sh
istioctl create -f telemetry.yaml
```

## (2) Diagnosability: Logs
```sh
kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio=mixer -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"

kubectl apply -f logging-stack.yaml
istioctl create -f fluentd-istio.yaml
kubectl expose deployment kibana --name=kibana-expose --port=5601 --target-port=5601 --type=LoadBalancer -n=logging

open http://localhost:5601/app/kibana
```
## (3) Diagnosability: Traces

###ServiceGraph
```sh
kubectl apply -f istio-*/install/kubernetes/addons/servicegraph.yaml
kubectl expose deployment servicegraph --name=servicegraph-expose --port=8088 --target-port=8088 --type=LoadBalancer -n=istio-system
open http://localhost:8088/dotviz
```

###Jaeger
```sh
kubectl apply -n istio-system -f 
https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml

kubectl expose deployment jaeger-deployment --name=jaeger-expose --port=16686 --target-port=16686 --type=LoadBalancer -n=istio-system

open http://127.0.0.1:16686
```

^
IMPORTANT: Header propagation / forwarding / relay required by application to remain traces

## (4) Perform load test

```sh
wget -P /usr/local/bin https://github.com/adersberger/slapper/releases/download/0.1/slapper
slapper -rate 4 -targets ./target -workers 2 -maxY 15s
```
see https://github.com/ikruglov/slapper

## (5) Canary Releases

Send all traffic for the user "jason" to the reviews:v2, meaning they'll only see the black stars.

```sh
istioctl create -f route-rule-reviews-test-v2.yaml
#open BookInfo application and login as user jason (password jason)
open http://localhost/productpage
```

The rule below ensures that 50% of the traffic goes to reviews:v1 (no stars), or reviews:v3 (red stars).

```sh
istioctl create -f route-rule-reviews-50-v3.yaml
#open BookInfo application and logout 
open http://localhost/productpage
```

Given the above approach, if the canary release were successful then we'd want to move 100% of the traffic to reviews:v3. This can be done by updating the route with new weighting and rules.

```sh
istioctl replace -f route-rule-reviews-v3.yaml
istioctl get routerules
istioctl delete routerule reviews-default -n default
istioctl delete routerule reviews-test-v2 -n default
```

## (7) mTLS

```sh
kubectl get configmap istio -o yaml -n istio-system | grep authPolicy | head -1
kubectl get pods -l app=productpage
kubectl exec -it productpage-v1-84f77f8747-zfdqt -c istio-proxy /bin/bash
ls /etc/certs/
```