-- ========================================================
-- SMARTFACTORY RE-INDEXING & OPTIMIZATION SCRIPT
-- ========================================================
USE smartfactory_db;

-- 1. Đo lường kích thước dữ liệu và index ban đầu
SELECT 
    table_name AS 'Table Name',
    ROUND(data_length / (1024 * 1024), 2) AS 'Data Size (MB)',
    ROUND(index_length / (1024 * 1024), 2) AS 'Index Size (MB)',
    ROUND((data_length + index_length) / (1024 * 1024), 2) AS 'Total Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'smartfactory_db' AND table_name = 'SensorLogs';

-- 2. Đánh giá truy vấn trước khi tối ưu (Sử dụng Covering Index)
-- Kết quả Extra sẽ có "Using index"
EXPLAIN SELECT temperature, humidity, status 
FROM SensorLogs 
WHERE sensor_id = 105 AND recorded_at >= '2026-06-20';

-- ========================================================
-- TIẾN HÀNH CHUYỂN ĐỔI: DROP FAT INDEX -> CREATE LEAN INDEX
-- ========================================================

-- Xóa "Fat Covering Index" gây nghẽn luồng ghi và phình to dung lượng ổ đĩa
ALTER TABLE SensorLogs DROP INDEX idx_fat_covering;

-- Tạo Lean Index chỉ chứa 2 cột phục vụ lọc điều kiện (WHERE)
CREATE INDEX idx_lean_search ON SensorLogs(sensor_id, recorded_at);

-- ========================================================
-- ĐỐI CHIẾU VÀ XÁC MINH HIỆU QUẢ SAU KHI TỐI ƯU
-- ========================================================

-- 3. Phân tích lại truy vấn Dashboard sau khi đổi sang Lean Index
-- Kết quả: key là 'idx_lean_search', type là 'range', không còn 'Using index'
-- (MySQL dùng index tìm sensor_id và recorded_at, sau đó đọc bảng gốc lấy metrics)
EXPLAIN SELECT temperature, humidity, status 
FROM SensorLogs 
WHERE sensor_id = 105 AND recorded_at >= '2026-06-20';

-- 4. Đo lường lại kích thước để chứng minh dung lượng Index_length đã giảm mạnh
SELECT 
    table_name AS 'Table Name',
    ROUND(data_length / (1024 * 1024), 2) AS 'Data Size (MB)',
    ROUND(index_length / (1024 * 1024), 2) AS 'Index Size (MB)',
    ROUND((data_length + index_length) / (1024 * 1024), 2) AS 'Total Size (MB)'
FROM information_schema.TABLES
WHERE table_schema = 'smartfactory_db' AND table_name = 'SensorLogs';