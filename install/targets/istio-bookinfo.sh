#!/bin/bash

HOST_IP=${DIND_HOST_IP:-127.0.0.1}

function init {
  pushd ~/.lab-k8s-cache/istio

  kubectl config set-context --current --namespace=default
  kubectl label namespace default istio-injection=enabled --overwrite
  kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
  kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

  kubectl -n istio-system port-forward --address $HOST_IP service/istio-ingressgateway 31380:80 >/dev/null &

  popd
}

function clean {
  pushd ~/.lab-k8s-cache/istio
  samples/bookinfo/platform/kube/cleanup.sh
  popd
}

command=${1:-init}

case $command in
  "init") init;;
  "clean") clean;;
  *) echo "* unkown command";;
esac
