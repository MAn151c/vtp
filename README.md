# VTP project
#Mô tả
Đây là dự án phân tích dữ liệu thương mại điện tử sử dụng SQL để xử lý dữ liệu thô và dùng PowerBI để xây dựng Star Schema và tạo ra các dashboard nhằm báo cáo các chỉ số cơ bản như AOV, Total Revenue,Total orders và biểu đồ FRM .
Đặc biệt, giao diện (UI/UX) được thiết kế bám sát **Brand Guideline của Viettel Post** (Màu Đỏ chủ đạo `#EE0033`, kết hợp cấu trúc Grid Layout chuẩn mực), nhằm mang lại trải nghiệm chuyên nghiệp, sạch sẽ và dễ đọc nhất cho cấp Quản lý (C-level).
--
## 🎯 Business Understanding & Key Questions
Dashboard này được thiết kế để giải quyết 4 nhóm vấn đề trọng tâm sau của doanh nghiệp:

1. **Đánh giá sức khỏe kinh doanh (Business Performance):**
   * *Câu hỏi:* Tổng doanh thu, lượng đơn hàng và giá trị trung bình trên mỗi đơn hàng (AOV) của công ty đang ở mức nào?
   * *Giải pháp:* Hệ thống Scorecard (Thẻ KPI) động, thay đổi theo thời gian và khu vực.
2. **Quản trị quan hệ & Phân khúc khách hàng (Customer Segmentation):**
   * *Câu hỏi:* Trong hàng vạn khách hàng, ai là tệp "Khách VIP" (Champions) cần chăm sóc đặc biệt? Ai là người đang "Ngủ đông" hoặc có nguy cơ rời bỏ (At Risk)?
   * *Giải pháp:* Áp dụng mô hình **RFM (Recency, Frequency, Monetary)** kết hợp biểu đồ Treemap để phân nhóm thị giác, hỗ trợ Marketing ra quyết định Retargeting chính xác.
3. **Tối ưu hóa chiến lược bán chéo (Cross-selling / Market Basket Analysis):**
   * *Câu hỏi:* Khách hàng thường mua kết hợp những sản phẩm nào với nhau? 
   * *Giải pháp:* Sử dụng Heatmap (Ma trận nhiệt) để tìm ra quy luật mua chéo, từ đó đề xuất thiết kế các Combo giảm giá hoặc cấu hình hệ thống Gợi ý (Recommendation System) trên web/app.
4. **Xác định động lực tăng trưởng (Growth Drivers):**
   * *Câu hỏi:* Nhóm ngành hàng nào đang "gánh" doanh thu cho toàn hệ thống? Xu hướng dòng tiền theo thời gian đang tăng hay giảm?
   * *Giải pháp:* Biểu đồ xu hướng Area Chart và xếp hạng Top 10 danh mục sản phẩm chủ lực.
---
##  Tech Stack & Workflow
* **Data Processing & ETL:** 
  * Sử dụng SQL nâng cao (CTEs, Window Functions, JOINs, Aggregations) để làm sạch, biến đổi dữ liệu thô.
  * Thiết lập các View SQL tổng hợp trước (Pre-aggregated views) cho logic RFM và Market Basket để tối ưu hóa hiệu suất load của Power BI.
* **Data Modeling:** Xây dựng mô hình **Star Schema** (Fact & Dimensions tables) chuẩn mực, giúp truy vấn mượt mà.
* **Data Visualization:** Power BI, DAX nâng cao (`CALCULATE`, `SUMX`, `DISTINCTCOUNT`).
* **Design & UI/UX:** Data Storytelling, Grid Layout, Conditional Formatting.
---
## 📂 Repository Structure
* `/1_SQL_Scripts`: Chứa toàn bộ các truy vấn ETL, logic tạo bảng RFM và thuật toán Market Basket Analysis.
* `/2_PowerBI_Dashboard`: Chứa file báo cáo gốc (`.pbix`) và bản xuất báo cáo nhanh (`.pdf`).
* `/3_Images`: Hình ảnh chụp màn hình Dashboard độ phân giải cao.
---
## 💡 Key Actionable Insights (Ví dụ)
1. **RFM Insights:** Nhóm "Champions" tuy chỉ chiếm một phần nhỏ số lượng nhưng lại đang đóng góp phần lớn tỷ trọng doanh thu. Cần có chính sách Loyalty Program (Điểm thưởng/Voucher riêng) cho nhóm này.
2. **Sales Insights:** Ngành hàng "Thời trang" và "Mỹ phẩm" là động lực doanh thu cốt lõi, nhưng giá trị trung bình đơn (AOV) của "Đồ gia dụng" lại cao nhất.
3. **Cross-sell Opportunities:** Ghi nhận tỷ lệ mua kèm cực cao giữa "Điện thoại" và "Phụ kiện". Đội ngũ Sales có thể áp dụng chiến thuật bundle pricing (bán theo gói) để tối đa hóa doanh thu trên mỗi phiên mua sắm.
---
## 🚀 How to explore this project
1. Đọc các file `.sql` trong thư mục `1_SQL_Scripts` để đánh giá tư duy xử lý dữ liệu và cấu trúc logic.
2. Mở file `.pdf` trong `2_PowerBI_Dashboard` để có cái nhìn tổng quan về giao diện báo cáo.
3. Để tương tác trực tiếp với dữ liệu (lọc theo năm, tháng, khu vực), hãy tải file `.pbix` và mở bằng Power BI Desktop.
