LOCAL_KNATIVE_PREFIX=dev.local
IMAGE_NAME=helloworld-python
TAG=0.0.1
CONTAINER_NAME=clown
CLUSTER_NAME=kourier-cluster

IMAGE_TAGGED=$(IMAGE_NAME):$(TAG)
LOCAL_IMAGE_TAGGED=$(LOCAL_KNATIVE_PREFIX)/$(IMAGE_NAME):$(TAG)

docker-build:
	docker build -t $(IMAGE_NAME):$(TAG) .

docker-run:
	docker run -p 8080:8080 --rm --name clown $(IMAGE_TAGGED)

docker-down:
	docker stop $(CONTAINER_NAME)
	docker rm $(CONTAINER_NAME)

docker-tag:
	docker tag $(IMAGE_TAGGED) $(LOCAL_IMAGE_TAGGED)

cluster-create:
	k3d cluster create $(CLUSTER_NAME) \
		--agents 1

cluster-image:
	k3d image import $(LOCAL_IMAGE_TAGGED) -c $(CLUSTER_NAME)

get-crds:
	curl -o k8s/serving-crds.yaml -L https://github.com/knative/serving/releases/download/v0.21.0/serving-crds.yaml && \
	curl -o k8s/serving-core.yaml -L https://github.com/knative/serving/releases/download/v0.21.0/serving-core.yaml && \
	curl -o k8s/kourier.yaml -L https://github.com/knative/net-kourier/releases/download/v0.18.0/kourier.yaml && \

apply-crds:
	kubectl apply -f k8s/serving-crds.yaml && \
	kubectl apply -f k8s/serving-core.yaml && \
	kubectl apply -f k8s/kourier.yaml && \
	kubectl patch configmap/config-network \
		  --namespace knative-serving \
			  --type merge \
				  --patch '{"data":{"ingress.class":"kourier.ingress.networking.knative.dev"}}' && \
	kubectl --namespace kourier-system get service kourier && \
	kubectl get pods --namespace knative-serving

verify-k8s:
	kubectl get ksvc $(IMAGE_NAME) --output=custom-columns=NAME:.metadata.name,URL:.status.url

# The value 10.43.56.61 will change based on the output of 
# kubectl --namespace kourier-system get service kourier 
curl-k8s:
	kubectl run --restart Never --image=curlimages/curl:7.75.0 curly -- \
		curl -H "Host: helloworld-python.default.example.com" 10.43.56.61
