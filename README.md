```python
import pandas as pd

try:
    fact = pd.read_csv('Fact_Orders_Messy.csv')
    cust = pd.read_csv('Dim_Customer.csv')
    prod = pd.read_csv('Dim_Product.csv')
    
    print("Fact columns:", fact.columns.tolist())
    print("Cust columns:", cust.columns.tolist())
    print("Prod columns:", prod.columns.tolist())
    
    print(fact.head(2))
    print(prod.head(2))
except Exception as e:
    print(e)


```

```text
Fact columns: ['order_id', 'customer_id', 'order_status', 'order_purchase_timestamp', 'order_item_id', 'product_id', 'price', 'freight_value']
Cust columns: ['customer_id', 'customer_unique_id', 'customer_city', 'customer_name']
Prod columns: ['product_id', 'product_category_name']
       order_id customer_id order_status order_purchase_timestamp  order_item_id product_id      price  freight_value
0  ORD_00002055    C_003718    DELIVERED               2025-07-24              1     P_0232  3960000.0        95000.0
1  ORD_00058440    C_004117    DELIVERED               2025-09-24              1     P_0411  2260000.0        97000.0
  product_id product_category_name
0     P_0001              Phụ kiện
1     P_0002              Phụ kiện


```

```python
import pandas as pd
import numpy as np

# Load data
fact = pd.read_csv('Fact_Orders_Messy.csv')
prod = pd.read_csv('Dim_Product.csv')

total_rows = len(fact)

# Clean data
print("Unique statuses:", fact['order_status'].unique())
fact_clean = fact[(fact['order_status'] != 'CANCELLED') & (fact['order_status'] != 'CANCELED')].copy()
fact_clean = fact_clean.dropna(subset=['customer_id'])

# Time range
fact_clean['order_purchase_timestamp'] = pd.to_datetime(fact_clean['order_purchase_timestamp'])
min_date = fact_clean['order_purchase_timestamp'].min().strftime('%m/%Y')
max_date = fact_clean['order_purchase_timestamp'].max().strftime('%m/%Y')
duration_months = (fact_clean['order_purchase_timestamp'].max() - fact_clean['order_purchase_timestamp'].min()).days // 30

# RFM
max_dt = fact_clean['order_purchase_timestamp'].max() + pd.Timedelta(days=1)
rfm = fact_clean.groupby('customer_id').agg({
    'order_purchase_timestamp': lambda x: (max_dt - x.max()).days,
    'order_id': 'nunique',
    'price': 'sum'
}).reset_index()
rfm.columns = ['customer_id', 'Recency', 'Frequency', 'Monetary']

# Assign RFM scores (using qcut, standard 4 bins)
# F might have few unique values, so rank method 'first' or custom bins
rfm['R_Score'] = pd.qcut(rfm['Recency'], q=4, labels=[4, 3, 2, 1])
# Frequency might have many 1s.
bins_f = [0, 1, 2, 3, np.inf]
rfm['F_Score'] = pd.cut(rfm['Frequency'], bins=bins_f, labels=[1, 2, 3, 4], include_lowest=True, duplicates='drop')
rfm['M_Score'] = pd.qcut(rfm['Monetary'], q=4, labels=[1, 2, 3, 4])

# Simple Champion definition: High R, F, M (e.g., R>=3, F>=3, M>=3)
rfm['RFM_Segment'] = rfm.apply(lambda row: 'Champions' if row['R_Score'] in [3,4] and row['F_Score'] in [3,4] and row['M_Score'] in [3,4] else 'Others', axis=1)

champions_pct = (rfm[rfm['RFM_Segment'] == 'Champions'].shape[0] / rfm.shape[0]) * 100
total_revenue = rfm['Monetary'].sum()
champions_rev = rfm[rfm['RFM_Segment'] == 'Champions']['Monetary'].sum()
champions_rev_pct = (champions_rev / total_revenue) * 100

# Join with product for category insights
fact_prod = fact_clean.merge(prod, on='product_id', how='left')
cat_revenue = fact_prod.groupby('product_category_name')['price'].sum().sort_values(ascending=False)
print("\nCategory Revenue:")
print(cat_revenue)

cat_orders = fact_prod.groupby('product_category_name')['order_id'].nunique()
cat_aov = (cat_revenue / cat_orders).sort_values(ascending=False)
print("\nCategory AOV:")
print(cat_aov)

# Market Basket Analysis (Simplified)
# Orders with each category
order_cats = fact_prod.groupby('order_id')['product_category_name'].apply(set)
total_valid_orders = len(order_cats)

# Probability of Phone
has_phone = order_cats.apply(lambda x: 'Điện thoại' in x).sum()
# Probability of Phone and Accessory
has_phone_and_acc = order_cats.apply(lambda x: 'Điện thoại' in x and 'Phụ kiện' in x).sum()

cross_sell_rate = (has_phone_and_acc / has_phone) * 100 if has_phone > 0 else 0

# Average cross sell rate for any pair (very rough estimation)
# Just calculate overall co-occurrence rate for pairs.
pairs = []
for items in order_cats:
    l = list(items)
    for i in range(len(l)):
        for j in range(i+1, len(l)):
            pairs.append(tuple(sorted([l[i], l[j]])))

from collections import Counter
pair_counts = Counter(pairs)
if ('Điện thoại', 'Phụ kiện') in pair_counts or ('Phụ kiện', 'Điện thoại') in pair_counts:
     phone_acc_count = pair_counts.get(('Điện thoại', 'Phụ kiện'), 0) + pair_counts.get(('Phụ kiện', 'Điện thoại'), 0)
else:
     phone_acc_count = 0

avg_pair_count = sum(pair_counts.values()) / len(pair_counts) if len(pair_counts) > 0 else 1
multiple = phone_acc_count / avg_pair_count if avg_pair_count > 0 else 0

print(f"Total Rows: {total_rows}")
print(f"Time: {min_date} to {max_date} ({duration_months} months)")
print(f"Champions % count: {champions_pct:.2f}%")
print(f"Champions % rev: {champions_rev_pct:.2f}%")
print(f"Phone + Acc cross sell rate: {cross_sell_rate:.2f}%")
print(f"Phone + Acc multiple vs avg: {multiple:.2f}")



```

```text
Unique statuses: ['DELIVERED' 'SHIPPED' 'CANCELED' 'PROCESSING']

Category Revenue:
product_category_name
Phụ kiện      1.135119e+11
Điện thoại    9.101717e+10
Thời trang    8.628984e+10
Gia dụng      6.103776e+10
Sách          4.278997e+10
Laptop        3.639609e+10
Mỹ phẩm       3.456747e+10
Đồ chơi       2.236117e+10
Name: price, dtype: float64

Category AOV:
product_category_name
Gia dụng      5.242443e+06
Thời trang    5.015102e+06
Phụ kiện      4.869039e+06
Đồ chơi       4.697725e+06
Điện thoại    4.049167e+06
Mỹ phẩm       3.715734e+06
Sách          3.490210e+06
Laptop        2.655680e+06
dtype: float64
Total Rows: 131320
Time: 10/2024 to 10/2026 (24 months)
Champions % count: 28.43%
Champions % rev: 44.46%
Phone + Acc cross sell rate: 9.45%
Phone + Acc multiple vs avg: 2.62


```

Dựa trên các lời khuyên từ Vietnam Data Analyst Forum và dữ liệu thực tế từ tập dataset của bạn (file `Fact_Orders_Messy.csv`, `Dim_Product.csv`, `Dim_Customer.csv`), tôi đã chạy thuật toán phân tích để lấy ra các con số chính xác.

Dưới đây là bản `README.md` đã được hoàn thiện với số liệu thực tế:

---

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

**⚙️ Cấu trúc thư mục (Dành cho người xem source code)**

* `/1_SQL_Scripts` : Chứa truy vấn ETL, logic tạo bảng RFM và thuật toán Market Basket.
* `/2_PowerBI_Dashboard` : Chứa file báo cáo gốc (`.pbix`) và bản PDF.
* `/3_Images` : Hình ảnh UI/UX (bám sát Brand Guideline Viettel Post với mã màu #EE0033).
