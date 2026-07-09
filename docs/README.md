# Tài Liệu Hệ Thống YAS GitOps

Chào mừng bạn đến với tài liệu kỹ thuật của hệ thống **YAS (Yet Another Shop)** được cải tiến và vận hành theo mô hình GitOps kết hợp với Istio Service Mesh và hệ thống giám sát Observability tập trung.

Thư mục `docs/` này chứa toàn bộ các hướng dẫn cấu hình, vận hành và giải thích chi tiết về mặt kiến trúc để bạn có thể nhanh chóng làm quen và làm chủ hệ thống.

---

## 🗺️ Bản Đồ Tài Liệu

Hãy lựa chọn tài liệu phù hợp với nhu cầu của bạn dưới đây:

### 1. 🏗️ [So sánh & Kiến Trúc Hệ Thống](comparison-and-architecture.md)
* **Nội dung:** Chi tiết các thay đổi cốt lõi so với dự án Nashtech YAS gốc (từ local Docker Compose sang Kubernetes Production-Ready). Sơ đồ kiến trúc CI/CD monorepo sử dụng Jenkins tích hợp quét bảo mật (Gitleaks, Snyk SCA), kiểm định mã nguồn (SonarQube) và tự động đồng bộ GitOps sang ArgoCD.

### 2. 🚀 [Hướng Dẫn Cài Đặt & Chạy Thử](setup-guide.md)
* **Nội dung:** Hướng dẫn chi tiết từng bước chuẩn bị môi trường Minikube (Ram, Disk), cấu hình Ingress, các lệnh shell setup hệ thống cơ sở dữ liệu hạ tầng (Postgres, Kafka, Elasticsearch, Keycloak) và deploy ứng dụng YAS. Hướng dẫn thiết lập `/etc/hosts` chia tách rạch ròi cho 3 phân vùng domain (`yas.local.com`, `yas.dev.com`, `yas.staging.com`).

### 3. 🐙 [Quản Lý GitOps Với ArgoCD](argocd-gitops.md)
* **Nội dung:** Nguyên lý vận hành GitOps và vai trò của ArgoCD. Kiến trúc mẫu **App-of-Apps Pattern** triển khai hệ thống vi dịch vụ, mô tả chi tiết sơ đồ thư mục cấu hình và quy trình tự động đồng bộ mã nguồn Docker qua Jenkins. Hướng dẫn CLI quản lý, kiểm tra trạng thái và Rollback ứng dụng.

### 4. 🕸️ [Lý Thuyết & Thực Hành Istio Service Mesh](service-mesh.md)
* **Nội dung:** Giải thích lý thuyết Service Mesh (Sidecar, mTLS, Traffic Routing, Authorization). Chi tiết cách cấu hình Istio trong hệ thống (`PeerAuthentication`, `AuthorizationPolicy`, `VirtualService`) và quy trình kiểm thử thực tế cơ chế tự động thử lại (Retry) khi backend gặp lỗi.

### 5. 📊 [Hướng Dẫn Sử Dụng Các Dashboard Giám Sát](dashboards-guide.md)
* **Nội dung:** Cách truy cập, xem và sử dụng các Dashboard tương ứng để kiểm tra sức khỏe hệ thống:
  * **ArgoCD:** Quản lý vòng đời ứng dụng GitOps.
  * **Grafana (Loki & Tempo):** Phân tích log tập trung và truy vết phân tán (Distributed Tracing), kỹ thuật liên kết vết log sang đồ thị span node graph.
  * **Kiali:** Quan sát topology mạng lưới Service Mesh trực quan.
  * **pgAdmin, AKHQ, Keycloak, Kibana:** Quản trị các thành phần cơ sở dữ liệu, message queue, bảo mật và logging thô.

### 6. 👁️ [Giám Sát Toàn Diện (Observability)](observability.md)
* **Nội dung:** Hướng dẫn chi tiết lý thuyết, khái niệm và cách sử dụng bộ ba giám sát Prometheus (Metrics), Loki (Logs) và Tempo (Traces) trên giao diện `grafana.yas.local.com` cùng kỹ thuật liên kết log-to-trace (correlation) để gỡ lỗi.

---
> [!NOTE]
> Tất cả các tài liệu được viết bằng định dạng Markdown tiêu chuẩn, hỗ trợ sơ đồ trực quan (Mermaid) và liên kết chéo tiện dụng. Nếu bạn gặp bất kỳ vấn đề gì trong quá trình cài đặt hoặc vận hành, vui lòng tham khảo [Hướng Dẫn Cài Đặt & Chạy Thử](setup-guide.md) trước tiên.
