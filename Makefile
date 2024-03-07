SHELL := /bin/bash

REGISTRY := rlregistry
REGISTRY_PORT := 8012
CLUSTER := ratelimits
INGRESS_PORT := 8011

GUBERNATOR_VERSION := 2.3.2

.PHONY = k3d-setup k3d-restart
.PHONY = gubernator-setup
.PHONY = helm-setup namespaces-setup
.PHONY = gubernator-deploy nginx-deploy

k3d-setup:
	k3d registry create $(REGISTRY).localhost --port $(REGISTRY_PORT)
	k3d cluster create --config k3d_config.yaml

k3d-restart:
	k3d cluster stop $(CLUSTER)
	k3d cluster start $(CLUSTER)

gubernator:
	curl -fsSL -o gubernator.tar.gz "https://github.com/mailgun/gubernator/archive/refs/tags/v$(GUBERNATOR_VERSION).tar.gz"
	tar -xzf gubernator.tar.gz
	rm -f gubernator.tar.gz
	mv "gubernator-$(GUBERNATOR_VERSION)" gubernator

gubernator-setup: gubernator

helm-setup: gubernator-setup
	helm diff -h 2&> /dev/null || helm plugin install https://github.com/databus23/helm-diff
	helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
	helm repo update

namespaces-setup:
	kubectl --context k3d-$(CLUSTER) apply -f k8s/namespaces.yaml

nginx-deploy:
	kubectl --context k3d-$(CLUSTER) --namespace ingress-nginx create configmap lua-limiter --from-file=main.lua -o yaml --dry-run=client | kubectl apply -f -
	helm upgrade --install --kube-context k3d-$(CLUSTER) --namespace ingress-nginx -f helm/nginx_values.yaml ingress-nginx ingress-nginx/ingress-nginx

gubernator-deploy: gubernator-setup
	helm upgrade --install --kube-context k3d-$(CLUSTER) --namespace gubernator -f helm/gubernator_values.yaml gubernator ./gubernator/contrib/charts/gubernator
	kubectl --context k3d-$(CLUSTER) --namespace gubernator apply -f k8s/ingress.yaml

dev-deploy:
	kubectl --context k3d-$(CLUSTER) --namespace dev apply -f k8s/dev.yaml
