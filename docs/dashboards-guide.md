# Hướng Dẫn Sử Dụng Các Dashboard Giám Sát

Hệ thống YAS được trang bị đầy đủ các giao diện trực quan hóa (Dashboards) để quản lý ứng dụng, giám sát hiệu năng, kiểm tra bảo mật và quản trị dữ liệu. Tài liệu này cung cấp hướng dẫn cách truy cập và sử dụng từng trang tương ứng.

---

## 🗺️ Bảng Tổng Hợp URL Truy Cập

*Trước khi truy cập, đảm bảo bạn đã hoàn thành việc cấu hình file hosts tại [Hướng Dẫn Cài Đặt & Chạy Thử](setup-guide.md).*

| Tên Dashboard | Địa Chỉ URL (Local) | Tài Khoản / Mật Khẩu | Mục Đích Chính |
| :--- | :--- | :--- | :--- |
| **ArgoCD** | `localhost:30080` (hoặc port-forward) | Do quản trị viên thiết lập | Giám sát và đồng bộ tài nguyên ứng dụng (GitOps). |
| **Grafana** | [http://grafana.yas.local.com](http://grafana.yas.local.com) | `admin` / `admin` (cấu hình mặc định) | Xem log tập trung (Loki), phân tích Trace (Tempo) và đo lường metrics. |
| **Kiali** | `localhost:20001` (hoặc port-forward) | Không yêu cầu | Xem mô hình mạng lưới mạng (Topology Graph) và cấu hình Istio. |
| **Keycloak** | [http://identity.yas.local.com](http://identity.yas.local.com) | Lấy từ secret `keycloak-credentials` | Quản lý danh tính người dùng (IAM), Realms, OAuth2 client. |
| **AKHQ** | [http://akhq.yas.local.com](http://akhq.yas.local.com) | Không yêu cầu | Giám sát các Topic, Broker và Consumer Group của Apache Kafka. |
| **pgAdmin** | [http://pgadmin.yas.local.com](http://pgadmin.yas.local.com) | `yasadminuser` / `admin` | Quản trị và truy vấn trực tiếp cơ sở dữ liệu PostgreSQL. |
| **Kibana** | [http://kibana.yas.local.com](http://kibana.yas.local.com) | Thiết lập trong elasticsearch-operator | Quản trị dữ liệu index và tìm kiếm trên Elasticsearch. |

---

## 1. ArgoCD - Quản Lý GitOps Deployments

ArgoCD giám sát các thay đổi trong repository `yas-gitops` và tự động đồng bộ chúng vào Kubernetes cluster.

### Hướng dẫn kiểm tra trạng thái:
1. Mở trình duyệt và truy cập ArgoCD (nếu dùng port-forward, chạy: `kubectl port-forward svc/argocd-server -n argocd 8080:443` rồi vào `https://localhost:8080`).
2. Giao diện hiển thị danh sách các ứng dụng (Application) tương ứng với các microservice của YAS (ví dụ: `dev-product`, `dev-cart`).
3. **Các dấu hiệu cần quan sát:**
   - **Trạng thái Sync:** Có màu xanh lá cây và nhãn `Synced` (đã đồng bộ khớp với Git). Nếu có nhãn màu vàng `OutOfSync`, nghĩa là mã nguồn trên Git đã thay đổi nhưng chưa được cập nhật dưới cluster.
   - **Trạng thái Health:** Biểu tượng trái tim màu xanh lá `Healthy` (ứng dụng đang chạy bình thường). Nếu có màu đỏ `Degraded` hoặc xám `Missing`, cần nhấp vào ứng dụng để xem Pod nào đang bị lỗi (CrashLoopBackOff, ImagePullBackOff).
4. Bạn có thể nhấn nút **Sync** để ép buộc đồng bộ hóa thủ công hoặc nhấn **Rollback** để khôi phục nhanh về commit trước đó nếu bản deploy mới bị lỗi.

---

## 2. Grafana - Phân Tích Log & Distributed Tracing

Grafana là công cụ phân tích tập trung kết nối dữ liệu từ **Loki** (Log) và **Tempo** (Trace/Truy vết cuộc gọi).

> [!TIP]
> Để hiểu sâu hơn về mặt khái niệm (Metrics, Logs, Traces), ngôn ngữ truy vấn (LogQL, PromQL, TraceQL) và cấu hình hạ tầng OpenTelemetry chi tiết của hệ thống YAS, hãy tham khảo tài liệu [Giám Sát Toàn Diện (Observability Guide)](observability.md).

### 2.1. Tra Cứu Log Tập Trung Với Loki
1. Truy cập [http://grafana.yas.local.com](http://grafana.yas.local.com).
2. Chọn menu **Explore** từ thanh công cụ bên trái (biểu tượng la bàn).
3. Tại menu thả xuống chọn nguồn dữ liệu (datasource), chọn **Loki**.
4. Sử dụng công cụ **Label filters** để lọc log:
   - `namespace` = Chọn `dev` hoặc `staging`.
   - `container` = Chọn tên microservice bạn muốn xem log (ví dụ: `product`, `storefront-bff`).
5. Nhấn **Run query** để tải các dòng log. Bạn có thể xem log thời gian thực bằng cách nhấn nút **Live**.

### 2.2. Phân Tích Tracing Phân Tán Với Tempo/Jaeger
Khi một request đi từ client qua nhiều microservice (ví dụ: storefront-bff -> product -> tax), distributed tracing giúp bạn đo lường thời gian xử lý của từng chặng.
1. Trong màn hình **Explore**, chọn datasource là **Tempo**.
2. Bạn có thể tìm kiếm vết theo Trace ID cụ thể hoặc dùng công cụ tìm kiếm lọc theo service.
3. Biểu đồ hiển thị dạng các thanh ngang (Span) mô tả thời gian chạy của từng hàm/chặng HTTP call nội bộ.
4. **Đồ thị Node Graph:** Chọn tab Node Graph để xem sơ đồ tương tác trực quan giữa các thành phần kèm theo tốc độ phản hồi (Latency) chi tiết của từng nút.

### 2.3. Kỹ Thuật Liên Kết Log-to-Trace (Log-to-Trace Correlation)
Hạ tầng OpenTelemetry đã được tích hợp để đính kèm `trace_id` tự động vào mọi dòng log.
- Khi xem log trên **Loki**, nhấp mở rộng chi tiết một dòng log bất kỳ có lỗi.
- Bạn sẽ thấy trường `traceID` hiển thị dưới dạng một liên kết màu xanh (thường có tên **Tempo**).
- Nhấp vào liên kết này, Grafana sẽ tự động chia đôi màn hình (Split screen) và mở trực tiếp biểu đồ vết Trace tương ứng của request đó bên cạnh dòng log. Kỹ thuật này giúp phát hiện ra nguyên nhân gốc rễ (Root cause) của lỗi hệ thống chỉ trong vài giây.

---

## 3. Kiali - Giám Sát Mạng Lưới Service Mesh

Kiali cung cấp cái nhìn toàn cảnh về kiến trúc liên kết mạng thực tế và trạng thái bảo mật của Istio Service Mesh.

### Hướng dẫn kiểm tra:
1. Mở trang Kiali (nếu chưa có ingress, chạy: `kubectl port-forward svc/kiali -n istio-system 20001:20001` và truy cập `http://localhost:20001`).
2. Chọn menu **Graph** ở bên trái.
3. Ở ô lọc namespace, tích chọn `dev` (hoặc `staging`).
4. Tại trình đơn **Display**, bật các tùy chọn:
   - **Traffic Animation:** Để thấy các chấm tròn di chuyển biểu thị luồng request đang chạy.
   - **Security:** Hiển thị biểu tượng ổ khóa móc (Padlock) trên các đường truyền mạng. 
5. **Cách đọc kết quả trực quan:**
   - **Đường truyền có ổ khóa đóng:** Giao tiếp mạng được bảo mật tuyệt đối bằng mã hóa **mTLS**.
   - **Đường truyền màu xanh lá:** Trạng thái kết nối tốt, tỷ lệ lỗi 0%.
   - **Đường truyền màu đỏ / cam:** Có lỗi HTTP 5xx hoặc latency cao xảy ra giữa hai service đó. Nhấp đúp vào nút đó để xem biểu đồ thống kê lỗi.

---

## 4. AKHQ - Quản Trị Hàng Đợi Tin Nhắn Kafka

AKHQ là giao diện tuyệt vời để kiểm tra các sự kiện bất đồng bộ truyền qua Apache Kafka (như đồng bộ dữ liệu sản phẩm, thông tin đơn hàng).

### Hướng dẫn kiểm tra:
1. Truy cập [http://akhq.yas.local.com](http://akhq.yas.local.com).
2. Chọn **Topics** ở menu trái để xem danh sách các kênh truyền tin.
3. Nhấp chọn một topic (ví dụ: `product-update`) -> Chọn tab **Data** để xem nội dung message dạng JSON đang được truyền qua.
4. Chọn **Consumer Groups** để xem danh sách các microservice đang lắng nghe tin nhắn và kiểm tra xem có service nào bị chậm tiến độ (Lag) dẫn đến nghẽn cổ chai dữ liệu hay không.

---

## 5. pgAdmin - Quản Trị Cơ Sở Dữ Liệu PostgreSQL

pgAdmin kết nối đến Zalando PostgreSQL Operator để quản trị các database của các microservice.

### Hướng dẫn sử dụng:
1. Truy cập [http://pgadmin.yas.local.com](http://pgadmin.yas.local.com).
2. Đăng nhập với tài khoản cấu hình trong `cluster-config.yaml` (mặc định: `yasadminuser` / `admin`).
3. Trong cây thư mục bên trái, bạn có thể truy cập vào các cơ sở dữ liệu độc lập của từng service (như `yas_product`, `yas_order`, `yas_customer`).
4. Sử dụng công cụ **Query Tool** để chạy các câu lệnh SQL kiểm tra dữ liệu thô phục vụ việc debug lỗi nghiệp vụ.
