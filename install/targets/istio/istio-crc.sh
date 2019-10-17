#!/bin/bash

LAB_HOME=${LAB_HOME:-`pwd`}
. $LAB_HOME/install/targets/istio/istio-base.sh
. $LAB_HOME/install/targets/istio/istio-openshift.sh

ISTIO_INSTALL_MODE=helm
ISTIO_CNI_ENABLED=true
ISTIO_CNI_BIN_DIR="/var/lib/cni/bin"
ISTIO_CNI_CONF_DIR="/etc/kubernetes/cni/net.d"

istio_conf="/etc/nginx/conf.d/istio.conf"

function login_as_admin {
  local adm_p=$(crc console --credentials | grep kubeadmin | sed "s/.*password is '\(.*\)'./\1/")
  oc login -u kubeadmin -p $adm_p https://api.crc.testing:6443
}

function add_endpoints {
  target::step "Add endpoints for istio"
  add_endpoint "istio" "Grafana" "http://grafana-istio-system.apps-crc.testing"
  add_endpoint "istio" "Kiali" "http://kiali-istio-system.apps-crc.testing"
  add_endpoint "istio" "Jaeger" "http://jaeger-query-istio-system.apps-crc.testing"
  add_endpoint "istio" "Prometheus" "http://prometheus-istio-system.apps-crc.testing"
}

function add_proxy {
  local service=$1
  if ! cat $istio_conf | grep -q "# For $service"; then
    cat $LAB_HOME/install/targets/istio/istio-nginx.conf | \
      sed -e "s/@@SERVICE/$service/g; s/@@HOST_IP/$HOST_IP/g" | \
      sudo tee -a $istio_conf
  fi
}

function istio::forward {
  if ensure_os_linux; then
    sudo touch $istio_conf
    add_proxy "grafana"
    add_proxy "kiali"
    add_proxy "jaeger-query"
    add_proxy "prometheus"
    sudo systemctl reload nginx
  else
    target::log "This is only supported on Linux."
  fi
}

function add_endpoints_bookinfo {
  target::step "Add endpoints for istio-bookinfo"
  add_endpoint "istio" "Istio Bookinfo" "http://istio-ingressgateway-istio-system.apps-crc.testing/productpage"
}

function istio-bookinfo::forward {
  if ensure_os_linux; then
    local hash_bucket_size="server_names_hash_bucket_size 128;"
    if ! cat $istio_conf | grep -q "$hash_bucket_size"; then
      echo $hash_bucket_size | sudo tee -a $istio_conf
      echo | sudo tee -a $istio_conf
    fi

    add_proxy "istio-ingressgateway"
    sudo systemctl reload nginx
  else
    target::log "This is only supported on Linux."
  fi
}

target::command $@
