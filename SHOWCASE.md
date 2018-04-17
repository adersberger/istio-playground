# Istio by Example

## (0) Open current environment
```sh
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
open https://istio.io/docs/tasks/telemetry/using-istio-dashboard.html
```

### Deploy Istio telemetry definition

```sh
istioctl create -f telemetry.yaml
```

wget -P /usr/local/bin https://github.com/adersberger/slapper/releases/download/0.1/slapper

slapper -rate 10 -targets ./target -workers 8 -maxY 15s

see https://github.com/ikruglov/slapper


## (2) Diagnosability: Logs
Logs:
kubectl -n istio-system logs $(kubectl -n istio-system get pods -l istio=mixer -o jsonpath='{.items[0].metadata.name}') mixer | grep \"instance\":\"newlog.logentry.istio-system\"

## (2) Diagnosability: Traces

#ServiceGraph
kubectl apply -f istio-*/install/kubernetes/addons/servicegraph.yaml
kubectl expose deployment servicegraph --name=servicegraph-expose --port=8088 --target-port=8088 --type=LoadBalancer -n=istio-system
open http://localhost:8088/dotviz

#Jaeger
kubectl apply -n istio-system -f 
https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml

kubectl expose deployment jaeger-deployment --name=jaeger-expose --port=16686 --target-port=16686 --type=LoadBalancer -n=istio-system

open http://127.0.0.1:16686

echo "GET http://localhost/productpage" | vegeta attack -duration=20s -rate=5 | tee results.bin | vegeta report

## (3) Traffic Management: Blue/Green Deployment, Dark Launches

send all traffic for the user "jason" to the reviews:v2, meaning they'll only see the black stars.

cat route-rule-reviews-test-v2.yaml

istioctl create -f route-rule-reviews-test-v2.yaml

#open BookInfo application and login as user jason (password jason)
open http://localhost/productpage

## (4) Traffic Management: Canary Releases, A/B Testing

The ability to split traffic for testing and rolling out changes is important. This allows for A/B variation testing or deploying canary releases.

The rule below ensures that 50% of the traffic goes to reviews:v1 (no stars), or reviews:v3 (red stars).

cat route-rule-reviews-50-v3.yaml

istioctl create -f route-rule-reviews-50-v3.yaml

#logout 

Given the above approach, if the canary release were successful then we'd want to move 100% of the traffic to reviews:v3.

This can be done by updating the route with new weighting and rules.

istioctl replace -f route-rule-reviews-v3.yaml

istioctl get routerules

istioctl delete routerule reviews-default -n default
istioctl delete routerule reviews-test-v2 -n default

Istioctl documentation: https://istio.io/docs/reference/commands/istioctl.html
