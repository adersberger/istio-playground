kubectl delete -f istio-*/install/kubernetes/istio-auth.yaml

kubectl delete -f istio-*/install/kubernetes/istio-sidecar-injector-configmap-release.yaml

kubectl delete -f istio-*/install/kubernetes/istio-sidecar-injector-with-ca-bundle.yaml

kubectl label namespace default istio-injection-