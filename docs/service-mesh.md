# Lý Thuyết & Thực Hành Istio Service Mesh

Tài liệu này giải thích khái niệm cơ bản về Service Mesh (Istio), cách cấu hình Istio trong hệ thống YAS và các bước thực hành kiểm thử cơ chế phục hồi lỗi (Retry).

---

## 1. Lý Thuyết Về Service Mesh

### 1.1. Service Mesh là gì?
Khi hệ thống chuyển từ kiến trúc đơn khối (Monolith) sang vi dịch vụ (Microservices), số lượng dịch vụ tăng lên kéo theo sự phức tạp trong giao tiếp mạng nội bộ. **Service Mesh** là một tầng hạ tầng chuyên dụng, được cấu hình trực tiếp vào hạ tầng mạng để quản lý giao tiếp giữa các service một cách an toàn, tin cậy và minh bạch.

Istio là một mã nguồn mở Service Mesh phổ biến nhất hiện nay, hoạt động dựa trên hai thành phần chính:
- **Data Plane (Mặt phẳng dữ liệu):** Gồm các mạng lưới proxy thông minh (sử dụng **Envoy Proxy**) được triển khai dưới dạng **Sidecar** chạy song song bên trong mỗi Pod ứng dụng. Mọi traffic ra/vào Pod đều đi qua sidecar proxy này.
- **Control Plane (Mặt phẳng điều khiển):** Thành phần **Istiod** quản lý và cấu hình các sidecar proxy để thực thi các chính sách định tuyến, bảo mật và thu thập dữ liệu giám sát.

```mermaid
graph TD
    subgraph Control Plane
        Istiod[Istiod: Quản lý Cấu hình & CA]
    end

    subgraph Pod A (Client)
        AppA[Ứng dụng A] <--> |Plaintext localhost| EnvoyA[Envoy Sidecar A]
    end

    subgraph Pod B (Server)
        AppB[Ứng dụng B] <--> |Plaintext localhost| EnvoyB[Envoy Sidecar B]
    end

    EnvoyA <--> |Mã hóa mTLS| EnvoyB
    Istiod -.-> |Gửi cấu hình| EnvoyA
    Istiod -.-> |Gửi cấu hình| EnvoyB
```

### 1.2. Các Lợi Ích Chính
1. **Traffic Management (Quản lý lưu lượng):** Hỗ trợ Canary deployment, A/B testing, tự động thử lại (Retries), cắt mạch (Circuit Breaking) và giới hạn băng thông.
2. **Security (Bảo mật Zero Trust):** Tự động mã hóa lưu lượng mạng nội bộ bằng mTLS, quản lý chứng chỉ số và phân quyền chi tiết (Authorization Policy).
3. **Observability (Khả năng quan sát):** Tự động đo lường phân tán (Distributed Tracing), thu thập metrics dịch vụ và log truy cập mạng.

---

## 2. Cấu Hình Istio Trong Hệ Thống YAS

Hệ thống YAS áp dụng 3 nhóm tài nguyên cấu hình Istio chính:

### 2.1. Mã Hóa Đường Truyền (mTLS) - `PeerAuthentication`
Tệp cấu hình: [mtls-peer-auth.yaml](file:///home/nhatthanh/yas-gitops/environments/dev/service_mesh/mtls-peer-auth.yaml)
- **Chế độ STRICT (Mặc định):** Bắt buộc mọi giao tiếp giữa các Pod nội bộ trong namespace `dev` phải sử dụng mã hóa mTLS. Nếu một Pod không thuộc mesh gọi đến sẽ bị từ chối.
- **Chế độ PERMISSIVE (Ngoại lệ):** Cấu hình riêng cho `nginx`, `storefront-bff`, và `backoffice-bff` do chúng phải nhận lưu lượng plain HTTP chưa mã hóa trực tiếp từ Nginx Ingress Controller (nằm ngoài Mesh).

### 2.2. Kiểm Soát Truy Cập - `AuthorizationPolicy`
Tệp cấu hình: [auth-policy.yaml](file:///home/nhatthanh/yas-gitops/environments/dev/service_mesh/auth-policy.yaml)
- Thiết lập quyền truy cập tối thiểu (Least Privilege).
- Ví dụ: Đối với service `search`, cấu hình chỉ cho phép các yêu cầu đến từ các Service Account `product`, `storefront-bff`, và `backoffice-bff`. Các service khác cố tình gọi sang sẽ bị Envoy block ngay lập tức với mã lỗi `403 Forbidden`.

### 2.3. Khả Năng Chịu Lỗi (Auto-Retry) - `VirtualService`
Tệp cấu hình: [global-retries.yaml](file:///home/nhatthanh/yas-gitops/environments/dev/service_mesh/global-retries.yaml)
- Khi một dịch vụ gặp lỗi tạm thời (chẳng hạn cơ sở dữ liệu bị lock, quá tải đột xuất dẫn đến mã lỗi HTTP 5xx), thay vì trả lỗi trực tiếp về cho client, Envoy Sidecar của client sẽ tự động gửi lại request.
- **Cấu hình áp dụng:**
  - Số lần thử lại tối đa (`attempts`): **3 lần**.
  - Thời gian chờ tối đa cho mỗi lần thử (`perTryTimeout`): **2 giây**.
  - Điều kiện kích hoạt (`retryOn`): `5xx, gateway-error, connect-failure, refused-stream`.

---

## 3. Thực Hành Kiểm Thử Cơ Chế Retry

Để trực quan hóa hoạt động của cơ chế tự động thử lại (Retry) của Istio Envoy, chúng ta sẽ thực hiện một bài test thực tế bằng cách giả lập lỗi HTTP 500.

### Kịch bản thử nghiệm
Chúng ta sử dụng một Client Pod trong mesh là `test-curl` để gọi tới dịch vụ giả lập lỗi `httpbin`. Dịch vụ này có endpoint `/status/500` luôn trả về mã lỗi 500.

```mermaid
sequenceDiagram
    participant User as test-curl App
    participant EnvoyClient as Envoy Sidecar (test-curl)
    participant EnvoyServer as Envoy Sidecar (httpbin)
    participant Httpbin as httpbin App

    User->>EnvoyClient: Gọi http://httpbin/status/500
    
    Note over EnvoyClient: Gửi request Lần 1 (Gốc)
    EnvoyClient->>EnvoyServer: HTTP GET /status/500
    EnvoyServer->>Httpbin: 
    Httpbin-->>EnvoyServer: Trả về HTTP 500
    EnvoyServer-->>EnvoyClient: Trả về HTTP 500
    
    Note over EnvoyClient: Nhận lỗi 500 -> Thử lại Lần 1
    EnvoyClient->>EnvoyServer: HTTP GET /status/500
    EnvoyServer->>Httpbin: 
    Httpbin-->>EnvoyServer: Trả về HTTP 500
    EnvoyServer-->>EnvoyClient: Trả về HTTP 500

    Note over EnvoyClient: Nhận lỗi 500 -> Thử lại Lần 2
    EnvoyClient->>EnvoyServer: HTTP GET /status/500
    EnvoyServer->>Httpbin: 
    Httpbin-->>EnvoyServer: Trả về HTTP 500
    EnvoyServer-->>EnvoyClient: Trả về HTTP 500

    Note over EnvoyClient: Nhận lỗi 500 -> Thử lại Lần 3 (Lần cuối)
    EnvoyClient->>EnvoyServer: HTTP GET /status/500
    EnvoyServer->>Httpbin: 
    Httpbin-->>EnvoyServer: Trả về HTTP 500
    EnvoyServer-->>EnvoyClient: Trả về HTTP 500

    Note over EnvoyClient: Đã hết lượt retry (URX)
    EnvoyClient-->>User: Trả về HTTP 500 cho ứng dụng
```

### Các bước thực hiện:

#### Bước 1: Deploy tài nguyên kiểm thử
Triển khai Pod `test-curl`, `httpbin` cùng với cấu hình `VirtualService` chứa luật retry riêng cho httpbin:
```bash
kubectl apply -f environments/dev/service_mesh/httpbin-retry-test.yaml
```

#### Bước 2: Thực hiện cuộc gọi giả lập lỗi từ Pod Client
Chạy lệnh curl từ bên trong container `curl` của Pod `test-curl` hướng tới dịch vụ `httpbin`:
```bash
kubectl exec -n dev test-curl -c curl -- curl -s -o /dev/null -w "%{http_code}" http://httpbin/status/500
```
*Kết quả trên terminal sẽ trả ra:* `500`.

#### Bước 3: Phân tích Log của Envoy Proxy tại đầu gửi (`test-curl`)
Xem log của Sidecar proxy (`istio-proxy`) của client:
```bash
kubectl logs -n dev test-curl -c istio-proxy --tail=10
```
> [!IMPORTANT]
> **Dấu hiệu thành công:** Trong log của `test-curl` Envoy sẽ xuất hiện dòng log chứa cờ **`URX`** (Upstream Retry Exhausted) cùng tham số `x-envoy-attempt-count` bằng `4` (1 cuộc gọi gốc + 3 lần thử lại).

#### Bước 4: Phân tích Log của Envoy Proxy tại đầu nhận (`httpbin`)
Xem log của Sidecar proxy phía nhận để kiểm tra số lượng request thực tế đi vào backend:
```bash
kubectl logs -n dev httpbin -c istio-proxy --tail=20 | grep "GET /status/500"
```
> [!IMPORTANT]
> **Dấu hiệu thành công:** Log của `httpbin` Envoy sẽ hiển thị chính xác **4 dòng log** yêu cầu truy cập `GET /status/500` có cùng một giá trị `X-Request-Id` được ghi nhận gần như đồng thời. Điều này chứng minh 1 request bị lỗi từ phía ứng dụng client đã được hạ tầng Envoy tự động nhân lên làm 4 lần thử trước khi từ bỏ.
