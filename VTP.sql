-- ==============================================================================
-- BƯỚC 1: LÀM SẠCH & CHUẨN HÓA DỮ LIỆU (ELT)
-- ==============================================================================
DROP VIEW IF EXISTS vw_Fact_Orders_Clean;

CREATE VIEW vw_Fact_Orders_Clean AS
WITH Ranked_Orders AS (
    -- Loại bỏ dữ liệu lặp (Duplicates)
    SELECT 
        *,
        ROW_NUMBER() OVER(
            PARTITION BY order_id, order_item_id 
            ORDER BY order_purchase_timestamp DESC
        ) as row_num
    FROM Fact_Orders_Messy
)
-- Xử lý Nulls, Outliers và Logic Doanh thu
SELECT 
    order_id,
    customer_id,
    product_id,
    UPPER(order_status) AS order_status,
    DATE(order_purchase_timestamp) AS order_date, -- Hàm DATE của SQLite
    
    -- Nếu trống thì gán bằng 0
    COALESCE(price, 0) AS price,
    COALESCE(freight_value, 0) AS freight_value,
    
    -- Đơn HỦY thì giá trị bằng 0 để không cộng vào Doanh thu
    CASE 
        WHEN UPPER(order_status) = 'CANCELED' THEN 0 
        ELSE (COALESCE(price, 0) + COALESCE(freight_value, 0)) 
    END AS total_revenue
    
FROM Ranked_Orders
WHERE row_num = 1
  AND customer_id IS NOT NULL 
  AND product_id IS NOT NULL
  -- Bỏ Outliers
  AND COALESCE(price, 0) >= 0 
  AND COALESCE(price, 0) < 500000000;


-- ==============================================================================
-- BƯỚC 2: PHÂN NHÓM KHÁCH HÀNG (RFM SEGMENTATION)
-- ==============================================================================
WITH Customer_RFM_Raw AS (
    SELECT 
        c.customer_unique_id,
        c.customer_name,
        -- Tính Recency bằng Julianday (Hàm đặc thù của SQLite thay cho DATEDIFF)
        CAST(julianday('2026-10-05') - julianday(MAX(f.order_date)) AS INTEGER) AS Recency_Days,
        
        -- Tính Frequency 
        COUNT(DISTINCT f.order_id) AS Frequency_Orders,
        
        -- Tính Monetary 
        SUM(f.total_revenue) AS Monetary_Value
    FROM vw_Fact_Orders_Clean f
    JOIN Dim_Customer_Fixed c ON f.customer_id = c.customer_id 
    WHERE f.order_status = 'DELIVERED'
    GROUP BY c.customer_unique_id, c.customer_name
),
RFM_Scores AS (
    SELECT 
        *,
        NTILE(5) OVER(ORDER BY Recency_Days DESC) AS R_Score, 
        NTILE(5) OVER(ORDER BY Frequency_Orders ASC) AS F_Score,
        NTILE(5) OVER(ORDER BY Monetary_Value ASC) AS M_Score
    FROM Customer_RFM_Raw
)
SELECT 
    *,
    -- Nối chuỗi bằng toán tử || trong SQLite
    CAST(R_Score AS TEXT) || CAST(F_Score AS TEXT) || CAST(M_Score AS TEXT) AS RFM_String,
    CASE 
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions' 
        WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers' 
        WHEN R_Score <= 2 AND F_Score >= 4 AND M_Score >= 4 THEN 'At Risk' 
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Hibernating' 
        ELSE 'Potential / Needs Attention' 
    END AS Customer_Segment
FROM RFM_Scores;


-- ==============================================================================
-- BƯỚC 3: PHÂN TÍCH GIỎ HÀNG (MARKET BASKET / CROSS-SELL)
-- ==============================================================================
WITH Order_Categories AS (
    SELECT DISTINCT f.order_id, p.product_category_name AS Category
    FROM vw_Fact_Orders_Clean f
    JOIN Dim_Product p ON f.product_id = p.product_id
),
Category_Counts AS (
    SELECT Category, COUNT(order_id) AS Total_Orders
    FROM Order_Categories
    GROUP BY Category
),
Category_Pairs AS (
    SELECT a.Category AS Category_A, b.Category AS Category_B, a.order_id
    FROM Order_Categories a
    JOIN Order_Categories b ON a.order_id = b.order_id
    WHERE a.Category != b.Category 
)
SELECT 
    p.Category_A AS Base_Product,
    p.Category_B AS Cross_Sell_Product,
    COUNT(p.order_id) AS Bought_Together_Times,
    c.Total_Orders AS Total_Base_Orders,
    
    -- Tính tỷ lệ phần trăm (Nhân 1.0 để ép kiểu số thực trong SQLite)
    ROUND((COUNT(p.order_id) * 1.0 / c.Total_Orders) * 100, 2) AS Cross_Sell_Confidence_Rate
FROM Category_Pairs p
JOIN Category_Counts c ON p.Category_A = c.Category
GROUP BY p.Category_A, p.Category_B, c.Total_Orders
HAVING ROUND((COUNT(p.order_id) * 1.0 / c.Total_Orders) * 100, 2) > 5
ORDER BY Cross_Sell_Confidence_Rate DESC;