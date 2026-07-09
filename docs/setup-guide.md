# Hướng Dẫn Cài Đặt và Chạy Thử Hệ Thống

Tài liệu này hướng dẫn chi tiết các bước chuẩn bị môi trường, cài đặt hạ tầng cơ sở dữ liệu, triển khai các dịch vụ YAS và cấu hình file hosts để truy cập hệ thống trên local.

---

## 1. Yêu Cầu Cấu Hình Môi Trường

Hệ thống YAS chạy trên nền tảng Kubernetes (Minikube). Để vận hành trơn tru toàn bộ các operator và microservices, máy chủ của bạn cần đáp ứng cấu hình tối thiểu sau:
- **Hệ điều hành:** Ubuntu (hoặc các bản phân phối Linux tương đương).
- **Phần cứng:** Tối thiểu **16 GB RAM** và **40 GB không gian đĩa trống**.
- **Công cụ yêu cầu sẵn có:** 
  - Docker (để Minikube sử dụng driver docker).
  - Git.

---

## 2. Các Bước Cài Đặt Chi Tiết

### Bước 1: Khởi động Minikube với cấu hình tài nguyên
Chạy lệnh khởi tạo Minikube với dung lượng đĩa và RAM như yêu cầu:
```bash
minikube start --disk-size='40000mb' --memory='16384mb' --cpus=4
```

### Bước 2: Kích hoạt Ingress Addon
Istio và Nginx API Gateway cần Ingress controller để định tuyến traffic từ ngoài vào cluster. Kích hoạt addon ingress của minikube bằng lệnh:
```bash
minikube addons enable ingress
```

### Bước 3: Cài đặt các công cụ CLI bổ sung
- **Helm:** Trình quản lý gói cho Kubernetes (dùng để cài đặt các chart).
- **yq:** Tiện ích xử lý file YAML bằng command-line (dùng để tự động thay đổi cấu hình trong scripts).

*Hướng dẫn cài đặt nhanh trên Ubuntu:*
```bash
# Cài đặt Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Cài đặt yq
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq
```

### Bước 4: Di chuyển vào thư mục hạ tầng và triển khai các Operator & Database
Di chuyển vào thư mục chứa scripts cấu hình trong repo `yas-gitops`:
```bash
cd infrastructure/scripts
```

1. **Cấu hình file `cluster-config.yaml`:**
   Mở file `cluster-config.yaml` để kiểm tra hoặc chỉnh sửa các cấu hình mặc định (như mật khẩu PostgreSQL, Keycloak, Grafana, Redis).
   
2. **Cài đặt Keycloak làm Identity Server:**
   ```bash
   chmod +x setup-keycloak.sh
   ./setup-keycloak.sh
   ```
   *Lưu ý:* Keycloak sẽ được cài đặt trong namespace `keycloak`.

3. **Cài đặt Redis làm Session Store:**
   ```bash
   chmod +x setup-redis.sh
   ./setup-redis.sh
   ```
   *Lưu ý:* Redis sẽ được cài đặt trong namespace `redis`.

4. **Cài đặt toàn bộ hạ tầng cơ sở dữ liệu và giám sát (PostgreSQL, Kafka, Elasticsearch, Loki, Tempo, Prometheus/Grafana, Cert-manager, OpenTelemetry Operator/Collector, Promtail):**
   ```bash
   chmod +x setup-cluster.sh
   ./setup-cluster.sh
   ```
   *Lưu ý:* Quá trình này sẽ tốn khoảng 5 - 10 phút tùy thuộc vào tốc độ mạng của bạn để pull toàn bộ các docker image lớn của các Operator.

5. **Kiểm tra trạng thái các Pod hạ tầng:**
   Đảm bảo tất cả các Pod trong các namespace `postgres`, `elasticsearch`, `kafka`, `keycloak`, `observability` đã ở trạng thái `Running` trước khi đi tiếp.
   ```bash
   kubectl get pods -A
   ```

### Bước 5: Triển khai các ứng dụng YAS
Sau khi hạ tầng sẵn sàng, chạy script để deploy toàn bộ các chart microservice của YAS:
```bash
chmod +x deploy-yas-applications.sh
./deploy-yas-applications.sh
```
Các dịch vụ microservice của YAS sẽ được triển khai vào namespace `dev` (hoặc `staging` tùy thuộc cấu hình ArgoCD).

---

## 3. Cấu Hình File `/etc/hosts`

Để truy cập các ứng dụng và dashboard từ trình duyệt local, bạn cần phân giải tên miền ảo về IP của Minikube.

### Bước 3.1: Lấy địa chỉ IP của Minikube
Chạy lệnh sau để lấy IP của máy ảo Minikube:
```bash
minikube ip
```
*Giả sử IP trả về là: `192.168.49.2`.*

### Bước 3.2: Cập nhật file `/etc/hosts`
Sử dụng quyền `sudo` để chỉnh sửa file `/etc/hosts` trên máy local của bạn:
```bash
sudo nano /etc/hosts
```

Thêm các dòng cấu hình sau (thay thế `192.168.49.2` bằng IP thực tế bạn vừa lấy được từ bước trên):

```text
# ==========================================
# 1. Nhóm Dịch Vụ Hạ Tầng Chung (Infrastructure)
# ==========================================
192.168.49.2 pgoperator.yas.local.com
192.168.49.2 pgadmin.yas.local.com
192.168.49.2 akhq.yas.local.com
192.168.49.2 kibana.yas.local.com
192.168.49.2 identity.yas.local.com
192.168.49.2 grafana.yas.local.com

# ==========================================
# 2. Nhóm Môi Trường Phát Triển (DEV Namespace)
# ==========================================
192.168.49.2 api.yas.dev.com
192.168.49.2 storefront.yas.dev.com
192.168.49.2 backoffice.yas.dev.com

# ==========================================
# 3. Nhóm Môi Trường Kiểm Thử (STAGING Namespace)
# ==========================================
192.168.49.2 api.yas.staging.com
192.168.49.2 storefront.yas.staging.com
192.168.49.2 backoffice.yas.staging.com
```

Lưu file lại (`Ctrl + O`, `Enter` và thoát bằng `Ctrl + X`).

---

## 4. Lấy Thông Tin Đăng Nhập Keycloak

Tài khoản quản trị viên của Keycloak (Keycloak bootstrap admin) được sinh tự động và lưu trong một Kubernetes Secret. Bạn có thể lấy mật khẩu này bằng lệnh:

```bash
kubectl get secret keycloak-credentials -n keycloak -o jsonpath="{.data.password}" | base64 --decode
```

- **URL Keycloak:** [http://identity.yas.local.com](http://identity.yas.local.com)
- **Tên đăng nhập:** `admin`
- **Mật khẩu:** Chuỗi giải mã thu được từ câu lệnh trên.

> [!WARNING]
> Tài khoản bootstrap admin chỉ là tài khoản tạm thời. Để bảo mật hệ thống, bạn nên tạo một tài khoản admin chính thức khác bên trong giao diện quản trị của Keycloak, sau đó xóa hoặc vô hiệu hóa tài khoản bootstrap tạm thời này.
