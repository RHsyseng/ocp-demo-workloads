#!/usr/bin/env bash

set -euo pipefail

DIRNAME=$(dirname $0)
SUBSCRIPTION="${DIRNAME}/manifests/amq-streams/amq-streams-olm-subscription.yaml"
MYCLUSTER="${DIRNAME}/manifests/amq-streams/amq-streams-mycluster.yaml"
WORKLOAD="${DIRNAME}/manifests/amq-streams/amq-streams-workload-deployment.yaml"
AMQ_WORKLOAD_NAMESPACE="${DIRNAME}/manifests/amq-streams/amq-streams-namespace.yaml"
PROMETHEUS="${DIRNAME}/manifests/monitoring/prometheus.yaml"
ALERTINGRULES="${DIRNAME}/manifests/monitoring/alerting-rules.yaml"
ALERTMANAGER="${DIRNAME}/manifests/monitoring/alertmanager.yaml"
GRAFANA="${DIRNAME}/manifests/monitoring/grafana.yaml"
KAFKA_DASHBOARD="${DIRNAME}/manifests/dashboards/amq-streams-kafka-dashboard.json"
ZOOKEEPER_DASHBOARD="${DIRNAME}/manifests/dashboards/amq-streams-zookeeper-dashboard.json"
AMQ_WORKLOAD_NS="amq-workload"
OCP_OPERATORS_NS="openshift-operators"

function printe {
    echo -e "\e[31m===> [ERROR] ${1}\e[0m"
}

function printc {
    echo -e "\e[1;36m===> ${1}\e[0m"
}

function check_kubeconfig {
    if [ -z ${KUBECONFIG:-} ]; then
        if [ ! -f ${HOME}/.kube/config ]; then
            printe "No kubeconfig found, exiting"
            exit 1
        fi
    fi
}

function oc_apply {
    MANIFEST=${1:-}
    NS=${2:-}

    if [ "x${MANIFEST}" == "x" ]; then
        printe "Missing file to apply"
        exit 1
    fi

    if [ "x${NS}" != "x" ]; then
        oc apply -f "${MANIFEST}" -n "${NS}" 1> /dev/null
        rc=$?
    else
        oc apply -f "${MANIFEST}" 1> /dev/null
        rc=$?
    fi

    if [ $rc -ne 0 ]; then
        printe "Error applying ${MANIFEST}"
        exit $rc
    fi
}

function check_sc {
  if [ -z $(oc get sc -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}') ]; then
    printe "No default StorageClass found, exiting"
    exit 1
  fi
}

printc "Checking for kubeconfig..."
check_kubeconfig

printc "Checking for a default StorageClass"
check_sc

printc "Creating AMQ Streams workload NS ${AMQ_WORKLOAD_NS}"
oc_apply ${AMQ_WORKLOAD_NAMESPACE}

printc "Creating AMQ Streams OLM subscription"
oc_apply ${SUBSCRIPTION}

while [ "x" == "x$(oc get pods -l name=amq-streams-cluster-operator -n ${OCP_OPERATORS_NS} 2> /dev/null)" ]; do
    sleep 5
done

oc wait --for condition=ready pods -l name=amq-streams-cluster-operator -n ${OCP_OPERATORS_NS} --timeout=2400s

printc "Deploying an AMQ Streams cluster"
oc_apply ${MYCLUSTER} ${AMQ_WORKLOAD_NS}

while [ "x" == "x$(oc get pods -l strimzi.io/name=my-cluster-zookeeper -n ${AMQ_WORKLOAD_NS} 2> /dev/null)" ]; do
    sleep 5
done

oc wait --for condition=ready pods -l strimzi.io/name=my-cluster-zookeeper -n ${AMQ_WORKLOAD_NS} --timeout=2400s

while [ "x" == "x$(oc get pods -l strimzi.io/name=my-cluster-kafka -n ${AMQ_WORKLOAD_NS} 2> /dev/null)" ]; do
    sleep 5
done

oc wait --for condition=ready pods -l strimzi.io/name=my-cluster-kafka -n ${AMQ_WORKLOAD_NS} --timeout=2400s

while [ "x" == "x$(oc get pods -l strimzi.io/name=my-cluster-entity-operator -n ${AMQ_WORKLOAD_NS} 2> /dev/null)" ]; do
    sleep 5
done

oc wait --for condition=ready pods -l strimzi.io/name=my-cluster-entity-operator -n ${AMQ_WORKLOAD_NS} --timeout=2400s

printc "Deploying AMQ Streams workload example"
oc_apply ${WORKLOAD} ${AMQ_WORKLOAD_NS}

while [ "x" == "x$(oc get pods -l app=kafka-producer-sasl -n ${AMQ_WORKLOAD_NS} 2> /dev/null)" ]; do
    sleep 5
done

oc wait --for condition=ready pods -l app=kafka-producer-sasl -n ${AMQ_WORKLOAD_NS} --timeout=2400s

while [ "x" == "x$(oc get pods -l app=kafka-consumer-sasl -n ${AMQ_WORKLOAD_NS} 2> /dev/null)" ]; do
    sleep 5
done

oc wait --for condition=ready pods -l app=kafka-consumer-sasl -n ${AMQ_WORKLOAD_NS} --timeout=2400s

printc "Deploying AMQ Streams monitoring"
oc_apply ${ALERTINGRULES} ${AMQ_WORKLOAD_NS}

sed -ie "s@###DEPLOYMENT_NS###@${AMQ_WORKLOAD_NS}@" ${PROMETHEUS}
sed -ie "s@###KAFKA_CLUSTER_NAME###@my-cluster@" ${PROMETHEUS}
oc_apply ${PROMETHEUS} ${AMQ_WORKLOAD_NS}

sleep 5
oc wait --for condition=ready pods -l name=prometheus -n ${AMQ_WORKLOAD_NS} --timeout=2400s

oc_apply ${ALERTMANAGER} ${AMQ_WORKLOAD_NS}
oc_apply ${GRAFANA} ${AMQ_WORKLOAD_NS}
sleep 5
oc wait --for condition=ready pods -l name=grafana -n ${AMQ_WORKLOAD_NS} --timeout=2400s

printc "Exposing Grafana and Prometheus"
oc expose svc prometheus -n ${AMQ_WORKLOAD_NS} || true
oc expose svc grafana -n ${AMQ_WORKLOAD_NS} || true

printc "Importing Grafana dashboards"
sleep 10
GRAFANA_ROUTE=$(oc get route grafana -n ${AMQ_WORKLOAD_NS} --template='{{ .spec.host }}')

curl -X POST "http://${GRAFANA_ROUTE}/api/datasources" -H "Content-Type: application/json" \
     --user admin:admin --data-binary '{ "name":"Prometheus","type":"prometheus","access":"proxy","url":"http://prometheus:9090","basicAuth":false,"isDefault":true }' > /dev/null 2>&1

curl -X POST "http://admin:admin@${GRAFANA_ROUTE}/api/dashboards/db" -d @${KAFKA_DASHBOARD} --header "Content-Type: application/json" > /dev/null 2>&1
curl -X POST "http://admin:admin@${GRAFANA_ROUTE}/api/dashboards/db" -d @${ZOOKEEPER_DASHBOARD} --header "Content-Type: application/json" > /dev/null 2>&1

printc "Done! AMQ Streams is ready to use!"
printc "Grafana URL: ${GRAFANA_ROUTE}"
printc "Grafana creds: admin/admin"
