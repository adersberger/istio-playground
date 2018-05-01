kubectl delete -f istio-*/install/kubernetes/addons/prometheus.yaml

kubectl delete -f istio-*/install/kubernetes/addons/grafana.yaml

istioctl delete -f telemetry.yaml

kubectl delete -f logging-stack.yaml

istioctl delete -f fluentd-istio.yaml

kubectl delete -f istio-*/install/kubernetes/addons/servicegraph.yaml

kubectl delete -n istio-system -f https://raw.githubusercontent.com/jaegertracing/jaeger-kubernetes/master/all-in-one/jaeger-all-in-one-template.yml