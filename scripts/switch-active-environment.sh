#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-status}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGOCD_NS="argocd"

DEV_APP="yas-dev"
STAGING_APP="yas-staging"

DEV_MANIFEST="${ROOT_DIR}/infrastructure/argocd/yas-dev.yaml"
STAGING_MANIFEST="${ROOT_DIR}/infrastructure/argocd/yas-staging.yaml"

print_usage() {
  cat <<USAGE
Usage:
  ./scripts/switch-active-environment.sh status
  ./scripts/switch-active-environment.sh dev
  ./scripts/switch-active-environment.sh staging
  ./scripts/switch-active-environment.sh none

Modes:
  status   Show current ArgoCD applications and namespaces only.
  dev      Activate dev root app and remove staging root app if present.
  staging  Activate staging root app and remove dev root app if present.
  none     Remove both dev and staging root applications.

Warning:
  Modes dev/staging/none can affect ArgoCD applications in the cluster.
  Do not run them unless the team agrees and cluster resources are enough.
USAGE
}

show_status() {
  echo "=== Namespaces ==="
  kubectl get ns | grep -E 'argocd|dev|staging' || true

  echo
  echo "=== Root ArgoCD apps ==="
  kubectl get applications.argoproj.io -n "${ARGOCD_NS}" \
    "${DEV_APP}" "${STAGING_APP}" 2>/dev/null || true

  echo
  echo "=== Child ArgoCD apps ==="
  kubectl get applications.argoproj.io -n "${ARGOCD_NS}" 2>/dev/null \
    | grep -E '^(dev-|staging-|yas-)' || true
}

delete_app_if_exists() {
  local app_name="$1"

  if kubectl get applications.argoproj.io -n "${ARGOCD_NS}" "${app_name}" >/dev/null 2>&1; then
    echo "Deleting ArgoCD application: ${app_name}"
    kubectl delete applications.argoproj.io -n "${ARGOCD_NS}" "${app_name}"
  else
    echo "ArgoCD application ${app_name} does not exist, skip."
  fi
}

case "${MODE}" in
  status)
    show_status
    ;;

  dev)
    echo "Activating DEV environment..."
    kubectl apply -f "${DEV_MANIFEST}"
    delete_app_if_exists "${STAGING_APP}"
    show_status
    ;;

  staging)
    echo "Activating STAGING environment..."
    kubectl apply -f "${STAGING_MANIFEST}"
    delete_app_if_exists "${DEV_APP}"
    show_status
    ;;

  none)
    echo "Disabling DEV and STAGING root applications..."
    delete_app_if_exists "${DEV_APP}"
    delete_app_if_exists "${STAGING_APP}"
    show_status
    ;;

  -h|--help|help)
    print_usage
    ;;

  *)
    echo "Unknown mode: ${MODE}"
    print_usage
    exit 1
    ;;
esac
