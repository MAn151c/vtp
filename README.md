

# Phân tích hiệu quả kinh doanh & Hành vi khách hàng (VTP Project)

**1. Câu hỏi kinh doanh**
Dự án này nhằm giúp Ban Giám đốc (C-level) trả lời câu hỏi: Nhóm khách hàng/ngành hàng nào đang mang lại giá trị cao nhất và làm thế nào để tối ưu hóa doanh thu bán chéo? Phân tích được thực hiện dựa trên tập dữ liệu giao dịch thương mại điện tử trong giai đoạn từ 10/2024 đến 10/2026.

**2. Nguồn dữ liệu**

* **Nguồn gốc:** Dữ liệu giao dịch thương mại điện tử nội bộ.
* **Cấu trúc:** Gồm các bảng chính (`Dim_Customer`, `Dim_Product`, `Fact_Orders_Messy`...).
* **Quy mô:** 131.320 dòng dữ liệu giao dịch gốc.
* **Khoảng thời gian:** 10/2024 đến 10/2026.

**3. Cách xử lý dữ liệu**

* **Làm sạch (Data Cleaning):** Bảng `Fact_Orders_Messy.csv` chứa nhiều dữ liệu rác. Tôi quyết định loại bỏ các đơn hàng có trạng thái "CANCELED" và các dòng thiếu `CustomerID` vì chúng không đóng góp vào doanh thu thực tế và làm sai lệch thuật toán phân nhóm RFM.
* **Tính toán chỉ số (Metric Calculation):** Sử dụng CTEs và Window Functions trong SQL để tính toán các điểm số R (Recency), F (Frequency), M (Monetary) trước khi load vào Power BI nhằm tối ưu hóa hiệu suất (Pre-aggregated views).
* **Mô hình hóa (Data Modeling):** Tổ chức dữ liệu theo mô hình Star Schema chuẩn mực để đảm bảo khả năng truy vấn chéo mượt mà.

**4. Kết quả chính (Key Actionable Insights)**

* **Phân khúc khách hàng:** Nhóm "Champions" tuy chỉ chiếm **28,4%** tổng số lượng khách hàng nhưng lại đang đóng góp tới **44,5%** tỷ trọng doanh thu toàn hệ thống.
* **Động lực tăng trưởng:** Ngành hàng "Phụ kiện" là động lực doanh thu cốt lõi, cao hơn **24,7%** so với ngành đứng thứ hai (Điện thoại), tuy nhiên giá trị trung bình đơn (AOV) của "Gia dụng" lại cao nhất, đạt **5,24 triệu VNĐ/đơn**.
* **Mối liên hệ mua chéo:** Ghi nhận tỷ lệ mua kèm giữa "Điện thoại" và "Phụ kiện" đạt mức **9,45%**, cao gấp **2,6 lần** so với mức độ xuất hiện chung của các tổ hợp sản phẩm khác.

**5. Đề xuất (Recommendations)**

* Dựa trên kết quả RFM, nên **thiết kế các gói đặc quyền (Voucher riêng, ưu tiên vận chuyển)** cho nhóm **Champions**, với điều kiện **ngân sách Loyalty Program quý tới cho phép trích lập 5% doanh thu dự kiến**. Nếu không có ngân sách, chỉ cần triển khai email hoặc tin nhắn cảm ơn cá nhân hóa.
* Dựa trên kết quả mua chéo, nên **thiết lập chiến thuật Bundle Pricing (bán theo gói)** đối với tổ hợp **Điện thoại & Phụ kiện**, với điều kiện **hệ thống Recommendation trên app/web có khả năng hiển thị mục "Thường được mua cùng nhau"** tại bước thanh toán.

**6. Hạn chế đã biết (Known Limitations)**
Kết quả phân khúc khách hàng RFM hiện tại chưa tính tới yếu tố **mùa vụ (seasonality)** và **chi phí hoàn hàng**, do dữ liệu hiện tại không có trường **lý do hoàn/hủy** và thời gian quan sát chỉ gói gọn trong **24 tháng**. Nếu có thêm dữ liệu lịch sử của các năm trước và chi phí logistics, phần phân loại khách hàng "At Risk" (Nguy cơ rời bỏ) có thể thay đổi và chính xác hơn về mặt lợi nhuận ròng.

---

** Cấu trúc thư mục 

* `/1_SQL_Scripts` : Chứa truy vấn ETL, logic tạo bảng RFM và thuật toán Market Basket.
* `/2_PowerBI_Dashboard` : Chứa file báo cáo gốc (`.pbix`) và bản PDF.

