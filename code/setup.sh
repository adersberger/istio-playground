# Start recording
asciinema rec ./istio-setup.cast --title="Istio by Example (Setup)" --idle-time-limit=2 -y

# Setup Istio
curl -L https://git.io/getLatestIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH
cd ..
kubectl apply -f istio-*/install/kubernetes/istio-auth.yaml
kubectl get pods -n istio-system

# Setup Istio auto-sidecar magic
./istio-*/install/kubernetes/webhook-create-signed-cert.sh \
--service istio-sidecar-injector \
--namespace istio-system \
--secret sidecar-injector-certs

kubectl apply -f istio-*/install/kubernetes/istio-sidecar-injector-configmap-release.yaml

cat istio-0.7.1/install/kubernetes/istio-sidecar-injector.yaml | \
     ./istio-0.7.1/install/kubernetes/webhook-patch-ca-bundle.sh > \
     istio-0.7.1/install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

kubectl apply -f istio-*/install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

# Label default namespace to be auto-sidecared
kubectl label namespace default istio-injection=enabled
kubectl get namespace -L istio-injection

# Deploy BookInfo sample application
kubectl apply -f istio-*/samples/bookinfo/kube/bookinfo.yaml
kubectl describe ingress
open http://localhost/productpage

# Play recording
asciinema play ./istio-setup.cast --idle-time-limit=2
asciinema upload ./istio-setup.cast

# Start recording
asciinema rec ./observability-setup.cast --title="Istio by Example (Observability Setup)" --idle-time-limit=2 -y

# Deploy Prometheus
kubectl apply -f istio-*/install/kubernetes/addons/prometheus.yaml
kubectl expose deployment prometheus --name=prometheus-expose --port=9090 --target-port=9090 --type=LoadBalancer -n=istio-system

# Deploy Grafana
kubectl apply -f istio-*/install/kubernetes/addons/grafana.yaml
kubectl expose deployment grafana --name=grafana-expose --port=3000 --target-port=3000 --type=LoadBalancer -n=istio-system
open http://localhost:3000/d/1/istio-dashboard

# Deploy EFK Stack
kubectl apply -f logging-stack.yaml
istioctl create -f fluentd-istio.yaml
kubectl expose deployment kibana --name=kibana-expose --port=5601 --target-port=5601 --type=LoadBalancer -n=logging
open http://localhost:5601/app/kibana

# Deploy Jaeger
kubectl apply -n istio-system -f https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml
kubectl expose deployment jaeger-deployment --name=jaeger-expose --port=16686 --target-port=16686 --type=LoadBalancer -n=istio-system
open http://127.0.0.1:16686

# Play recording
asciinema play ./observability-setup.cast --idle-time-limit=2
asciinema upload ./observability-setup.cast