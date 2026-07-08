#!/bin/bash
set -x

# Tự động cập nhật hoặc khởi động lại khi thay đổi ConfigMap/Secret
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update

read -rd '' DOMAIN \
< <(yq -r '.domain' ./cluster-config.yaml)

# =====================================================================
# 🚨 PHẦN 1: TẮT HOÀN TOÀN CỤM BACKOFFICE (Giao diện quản trị - TIẾT KIỆM RAM)
# =====================================================================
# helm dependency build ../charts/backoffice-bff
# helm upgrade --install backoffice-bff ../charts/backoffice-bff \
# --namespace yas --create-namespace \
# --set backend.ingress.host="backoffice.$DOMAIN"

# helm dependency build ../charts/backoffice-ui
# helm upgrade --install backoffice-ui ../charts/backoffice-ui \
# --namespace yas --create-namespace

# sleep 60

# =====================================================================
#  PHẦN 2: BẬT CỤM STOREFRONT (Giao diện mua sắm phục vụ người dùng)
# =====================================================================
# 1. Khởi chạy Storefront BFF (Cổng định tuyến API cho Frontend)
helm dependency build ../charts/storefront-bff
helm upgrade --install storefront-bff ../charts/storefront-bff \
--namespace yas --create-namespace \
--set backend.ingress.host="storefront.$DOMAIN"

# 2. Khởi chạy Storefront UI (Ứng dụng Next.js hiển thị giao diện)
helm dependency build ../charts/storefront-ui
helm upgrade --install storefront-ui ../charts/storefront-ui \
--namespace yas --create-namespace

sleep 30

# =====================================================================
#  PHẦN 3: GIỮ LẠI SWAGGER UI (Để test/gọi thử API trực tiếp)
# =====================================================================
helm upgrade --install swagger-ui ../charts/swagger-ui \
--namespace yas --create-namespace \
--set ingress.host="api.$DOMAIN"

sleep 20

# =====================================================================
#  PHẦN 4: CHỈ CHẠY CÁC BUSINESS SERVICES CỐT LÕI NỀN TẢNG
# =====================================================================
# Chúng ta chỉ bật 2 service quan trọng nhất:
# - Thằng 'product' gánh dữ liệu hàng hóa hiển thị lên trang Storefront.
# - Thằng 'tax' để chấm điểm Job CD developer_build theo yêu cầu.

for chart in "product" "tax" ; do
    helm dependency build ../charts/"$chart"
    helm upgrade --install "$chart" ../charts/"$chart" \
    --namespace yas --create-namespace \
    --set backend.ingress.host="api.$DOMAIN"
    sleep 30
done
