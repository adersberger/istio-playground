footer: Istio by Example, @adersberger, KubeCon & CloudNativeCon EU 2018
background-color: 283D8F

![](img/header-slide.png)

[.hide-footer]

---

# Why?

---

![fit](img/book.png)

^ because it's the hottest shit on earth

[.hide-footer]

---

![](img/adersberger-istio-by-example/adersberger-istio-by-example.001.jpeg)

[.hide-footer]

---
![](img/adersberger-istio-by-example/adersberger-istio-by-example.002.png)

[.hide-footer]
---
# Library Bloat
![](img/adersberger-istio-by-example/adersberger-istio-by-example.002.png)

[.hide-footer]

---

![](img/adersberger-istio-by-example/adersberger-istio-by-example.006.png)

[.hide-footer]

---

![](img/adersberger-istio-by-example/adersberger-istio-by-example.007.png)

[.hide-footer]

---
#Setting the sails with Istio
![](img/purple-3054804.jpg)

---
Features


| Traffic Management | Resiliency | Security | Observability |
| --- | --- | --- | --- |
| Request Routing | Timeouts | mTLS | Metrics |
| Load Balancing | Circuit Breaker | Access Control | Logs |
| Traffic Shifting | Health Checks (active, passive) | Workload Identity | Traces|
| Traffic Mirroring | Retries | RBAC |  |
| Service Discovery | Rate Limiting |  |  |
| Ingress, Egress | Delay & Fault Injection |  |  |

---

# Deploy Observability Add-Ons
 ```zsh
#Prometheus
kubectl apply -f istio-*/install/kubernetes/addons/prometheus.yaml
kubectl expose deployment prometheus --name=prometheus-expose 
        --port=9090 --target-port=9090 --type=LoadBalancer -n=istio-system

#Grafana
kubectl apply -f istio-*/install/kubernetes/addons/grafana.yaml
kubectl expose deployment grafana --name=grafana-expose 
        --port=3000 --target-port=3000 --type=LoadBalancer -n=istio-system

#Jaeger
kubectl apply -n istio-system -f 
https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/
master/all-in-one/jaeger-all-in-one-template.yml
kubectl expose deployment jaeger-deployment --name=jaeger-expose 
        --port=16686 --target-port=16686 --type=LoadBalancer -n=istio-system

#EFK
kubectl apply -f logging-stack.yaml
kubectl expose deployment kibana --name=kibana-expose 
        --port=5601 --target-port=5601 --type=LoadBalancer -n=logging
```

---
# Canary Releases: A/B Testing

 ```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-test-v2
spec:
  destination:
    name: reviews
  precedence: 2
  match:
    request:
      headers:
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
  route:
  - labels:
      version: v2
```
```zsh
istioctl create -f route-rule-reviews-test-v2.yaml
```
---
# Canary Releases: Rolling Upgrade

 ```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-default
spec:
  destination:
    name: reviews
  precedence: 1
  route:
  - labels:
      version: v1
    weight: 50
  - labels:
      version: v3
    weight: 50
```
```zsh
istioctl create -f route-rule-reviews-50-v3.yaml
```
---
# Canary Releases: Blue/Green
 ```yaml
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: reviews-default
spec:
  destination:
    name: reviews
  precedence: 1
  route:
  - labels:
      version: v3
    weight: 100
```
```zsh
istioctl replace -f route-rule-reviews-v3.yaml
```

---
# Security: Access Control
 ```yaml
apiVersion: "config.istio.io/v1alpha2"
kind: denier
metadata:
  name: denyreviewsv3handler
spec:
  status:
    code: 7
    message: Not allowed
---
apiVersion: "config.istio.io/v1alpha2"
kind: checknothing
metadata:
  name: denyreviewsv3request
spec:
---
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: denyreviewsv3
spec:
  match: source.labels["layer"]=="inner" && destination.labels["layer"] == "outer"
  actions:
  - handler: denyreviewsv3handler.denier
    instances: [ denyreviewsv3request.checknothing ]
```
^
https://medium.com/@szihai_37982/how-to-write-istio-mixer-policies-50dc639acf75

---

# Security: Egress
 ```yaml
apiVersion: networking.istio.io/v1alpha3
kind: ExternalService
metadata:
  name: google-ext
spec:
  hosts:
  - www.google.com
  ports:
  - number: 443
    name: https
    protocol: http
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: google-ext
spec:
  name: www.google.com
  trafficPolicy:
    tls:
      mode: SIMPLE # initiates HTTPS when talking to www.google.com
```

---
# Resiliency: Circuit Breaker
 ```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  name: httpbin
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      http:
        consecutiveErrors: 1
        interval: 1s
        baseEjectionTime: 3m
        maxEjectionPercent: 100
 ```
---

#https://github.com/adersberger/istio-by-example

---
![](img/final-slide.png)

[.hide-footer]
