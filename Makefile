REGISTRY ?= 10.16.231.128:5000
REGISTRY_USER ?= "openshift"
REGISTRY_PASSWORD ?= "redhat"
REGISTRY_CERT ?= "domain.crt"
NODE_LABEL ?= "worker-cnf"
PULL_SECRET ?= $(HOME)/.docker/config.json
DRIVER_TOOLKIT_IMAGE ?= $(shell oc adm release info --image-for=driver-toolkit -a $(PULL_SECRET))
KUBECONFIG ?= $(HOME)/.kube/config
KERNEL_VERSION ?= $(shell hack/get_kernel_version_from_node.sh $(NODE_LABEL) $(KUBECONFIG))

.PHONY: deploy build

pull_secret:
	oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > ${PULL_SECRET}
	oc registry login --skip-check --registry="${REGISTRY}" --auth-basic="${REGISTRY_USER}:${REGISTRY_PASSWORD}" --to=${PULL_SECRET}
	oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=${PULL_SECRET}


registry_cert:
	@{ \
	set -e ;\
	if ! oc get configmap registry-cas -n openshift-config >/dev/null; then \
	oc create configmap registry-cas -n openshift-config --from-file=$(subst :,..,${REGISTRY})=${REGISTRY_CERT}; \
	oc patch image.config.openshift.io/cluster --patch '{"spec":{"additionalTrustedCA":{"name":"registry-cas"}}}' --type=merge; \
	fi \
	}


login_registry:
ifdef REGISTRY_USER
        podman login -u ${REGISTRY_USER} -p ${REGISTRY_PASSWORD} ${REGISTRY}
endif


build: login_registry
	podman build --build-arg KVER=${KERNEL_VERSION} --build-arg DRIVER_TOOLKIT_IMAGE=${DRIVER_TOOLKIT_IMAGE} -t ${REGISTRY}/iavf-kmod-driver-container:demo -f Dockerfile.iavf .
	podman push ${REGISTRY}/iavf-kmod-driver-container:demo

deploy: pull_secret registry_cert build
	export REGISTRY=$(REGISTRY) NODE_LABEL=$(NODE_LABEL) ;\
	envsubst < iavf-install.yaml.template > iavf-install.yaml
	oc create -f iavf-install.yaml

destroy: iavf-install.yaml
	oc delete -f iavf-install.yaml
	
