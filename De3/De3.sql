-- ======================================================================
-- ĐỀ THI MÁY CHẴN - MÔN: CSDL NÂNG CAO, NGÀY THI: 05/05/2019
-- Lưu file thành: S:\MaSoMayTinh_MSSV_HoTenKhongDau_DeChan.sql
-- ======================================================================

-- **********************************************************************
-- PHẦN 1: Phân mảnh ngang chính và phân mảnh ngang dẫn xuất (4 điểm)
-- **********************************************************************

-- ==========================================================
-- Câu 1: (2 điểm) Tạo PM ngang bảng PhongBan và NhanVien
-- ==========================================================

-- Tạo PROC TaoPM_Ngang_PhongBan:
CREATE PROC TaoPM_Ngang_PhongBan
AS
    -- Xóa bảng nếu đã tồn tại để tiện test nhiều lần
    IF OBJECT_ID('PB_SG', 'U') IS NOT NULL DROP TABLE PB_SG;
    IF OBJECT_ID('PB_HN', 'U') IS NOT NULL DROP TABLE PB_HN;

    SELECT * INTO PB_SG FROM PhongBan WHERE ChiNhanh = N'Sài gòn'
    SELECT * INTO PB_HN FROM PhongBan WHERE ChiNhanh = N'Hà nội'
GO

-- Test PROC TaoPM_Ngang_PhongBan:
EXEC TaoPM_Ngang_PhongBan
GO

-- Tạo PROC TaoPM_Ngang_NhanVien:
CREATE PROC TaoPM_Ngang_NhanVien
AS
    IF OBJECT_ID('NV_SG', 'U') IS NOT NULL DROP TABLE NV_SG;
    IF OBJECT_ID('NV_HN', 'U') IS NOT NULL DROP TABLE NV_HN;

    SELECT * INTO NV_SG FROM NhanVien WHERE MaPB IN (SELECT MaPB FROM PB_SG)
    SELECT * INTO NV_HN FROM NhanVien WHERE MaPB IN (SELECT MaPB FROM PB_HN)
GO

-- Test PROC TaoPM_Ngang_NhanVien:
EXEC TaoPM_Ngang_NhanVien
GO

-- ==========================================================
-- Câu 2: (2 điểm) Tạo stored procedure tên SuaPB_Ngang
-- ==========================================================

-- Tạo PROC SuaPB_Ngang:
CREATE PROC SuaPB_Ngang
@MaPB NVARCHAR(10),
@TenPB NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    -- Xử lý ngoại lệ
    IF (@MaPB IS NULL OR @TenPB IS NULL OR @ChiNhanh IS NULL)
        PRINT N'Lỗi: Không được để trống Mã PB, Tên PB hoặc Chi nhánh!'
    ELSE IF @ChiNhanh NOT IN (N'Sài gòn', N'Hà nội')
        PRINT N'Lỗi: Chi nhánh không hợp lệ (Chỉ nhận Sài gòn hoặc Hà nội)!'
    ELSE IF NOT EXISTS (SELECT * FROM PB_SG WHERE MaPB = @MaPB) 
        AND NOT EXISTS (SELECT * FROM PB_HN WHERE MaPB = @MaPB)
        PRINT N'Lỗi: Không tìm thấy Mã phòng ban để sửa!'
    
    -- Thực hiện Sửa
    ELSE IF EXISTS (SELECT * FROM PB_SG WHERE MaPB = @MaPB)
    BEGIN
        -- Đang ở PM Sài Gòn
        UPDATE PB_SG SET TenPB = @TenPB, ChiNhanh = @ChiNhanh WHERE MaPB = @MaPB
        
        IF @ChiNhanh = N'Hà nội'
        BEGIN
            -- Dời dữ liệu sang Hà Nội
            INSERT INTO PB_HN SELECT * FROM PB_SG WHERE MaPB = @MaPB
            DELETE FROM PB_SG WHERE MaPB = @MaPB
            
            -- Dời nhân viên tương ứng
            INSERT INTO NV_HN SELECT * FROM NV_SG WHERE MaPB = @MaPB
            DELETE FROM NV_SG WHERE MaPB = @MaPB
            
            PRINT N'Thành công: Sửa và dời dữ liệu (Phòng ban + Nhân viên) từ Sài Gòn sang Hà Nội!'
        END
        ELSE
            PRINT N'Thành công: Đã sửa dữ liệu tại phân mảnh Sài Gòn (Không dời)!'
    END
    ELSE IF EXISTS (SELECT * FROM PB_HN WHERE MaPB = @MaPB)
    BEGIN
        -- Đang ở PM Hà Nội
        UPDATE PB_HN SET TenPB = @TenPB, ChiNhanh = @ChiNhanh WHERE MaPB = @MaPB
        
        IF @ChiNhanh = N'Sài gòn'
        BEGIN
            -- Dời dữ liệu sang Sài Gòn
            INSERT INTO PB_SG SELECT * FROM PB_HN WHERE MaPB = @MaPB
            DELETE FROM PB_HN WHERE MaPB = @MaPB
            
            -- Dời nhân viên tương ứng
            INSERT INTO NV_SG SELECT * FROM NV_HN WHERE MaPB = @MaPB
            DELETE FROM NV_HN WHERE MaPB = @MaPB
            
            PRINT N'Thành công: Sửa và dời dữ liệu (Phòng ban + Nhân viên) từ Hà Nội sang Sài Gòn!'
        END
        ELSE
            PRINT N'Thành công: Đã sửa dữ liệu tại phân mảnh Hà Nội (Không dời)!'
    END
GO

-- Test PROC SuaPB_Ngang:
PRINT N'--- TEST CÂU 2 ---'
EXEC SuaPB_Ngang NULL, N'Quảng cáo', N'Sài gòn'                 -- Báo lỗi NULL
EXEC SuaPB_Ngang N'PB01', N'Quảng cáo', NULL                    -- Báo lỗi NULL
EXEC SuaPB_Ngang N'PB01', N'Quảng cáo', N'Đà Nẵng'              -- Báo lỗi Chi nhánh
EXEC SuaPB_Ngang N'PB99', N'Tài chính', N'Sài gòn'              -- Báo lỗi Không tìm thấy
EXEC SuaPB_Ngang N'PB01', N'Phòng Thiết Kế', N'Sài gòn'         -- Thành công (Không dời)
EXEC SuaPB_Ngang N'PB01', N'Phòng Thiết Kế', N'Hà nội'          -- Thành công (Sửa và Dời từ SG -> HN)
GO


-- **********************************************************************
-- PHẦN 2: Phân mảnh dọc (4 điểm)
-- **********************************************************************

-- ==========================================================
-- Câu 3: (1 điểm) Hãy viết Stored procedure tên: TaoPM_Doc_PhongBan
-- ==========================================================

-- Tạo PROC TaoPM_Doc_PhongBan:
CREATE PROC TaoPM_Doc_PhongBan
AS
    IF OBJECT_ID('PhongBan_Doc1', 'U') IS NOT NULL DROP TABLE PhongBan_Doc1;
    IF OBJECT_ID('PhongBan_Doc2', 'U') IS NOT NULL DROP TABLE PhongBan_Doc2;

    SELECT MaPB, TenPB INTO PhongBan_Doc1 FROM PhongBan
    SELECT MaPB, ChiNhanh INTO PhongBan_Doc2 FROM PhongBan
GO

-- Test PROC TaoPM_Doc_PhongBan:
EXEC TaoPM_Doc_PhongBan
GO

-- ==========================================================
-- Câu 4: (1 điểm) Hãy viết Stored procedure tên: XemPB_Doc
-- ==========================================================

-- Tạo PROC XemPB_Doc:
CREATE PROC XemPB_Doc
AS
    SELECT D1.MaPB, D1.TenPB, D2.ChiNhanh
    FROM PhongBan_Doc1 D1
    JOIN PhongBan_Doc2 D2 ON D1.MaPB = D2.MaPB
    -- ĐÂY CHÍNH LÀ ĐOẠN SINH VIÊN QUÊN LÀM BỊ TRỪ ĐIỂM:
    WHERE D1.TenPB IN (N'Thiết kế', N'Kế toán')
GO

-- Test PROC XemPB_Doc:
EXEC XemPB_Doc
GO

-- ==========================================================
-- Câu 5: (2 điểm) Tạo stored procedure tên ThemPB_Doc
-- ==========================================================

-- Tạo PROC ThemPB_Doc:
CREATE PROC ThemPB_Doc
@MaPB NVARCHAR(10),
@TenPB NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    IF (@MaPB IS NULL OR @TenPB IS NULL OR @ChiNhanh IS NULL)
        PRINT N'Lỗi: Không được để trống tham số!'
    ELSE IF @ChiNhanh NOT IN (N'Sài gòn', N'Hà nội')
        PRINT N'Lỗi: Chi nhánh không hợp lệ!'
    ELSE IF EXISTS (SELECT * FROM PhongBan_Doc1 WHERE MaPB = @MaPB)
        PRINT N'Lỗi: Mã Phòng ban đã tồn tại, không thể thêm!'
    ELSE
    BEGIN
        INSERT INTO PhongBan_Doc1 VALUES (@MaPB, @TenPB)
        INSERT INTO PhongBan_Doc2 VALUES (@MaPB, @ChiNhanh)
        PRINT N'Thành công: Đã thêm dữ liệu vào 2 phân mảnh dọc!'
    END
GO

-- Test PROC ThemPB_Doc:
PRINT N'--- TEST CÂU 5 ---'
EXEC ThemPB_Doc NULL, N'Quảng cáo', N'Sài gòn'                  -- Lỗi NULL
EXEC ThemPB_Doc N'PB10', N'Nhân sự', N'Đà Nẵng'                 -- Lỗi Chi nhánh
EXEC ThemPB_Doc N'PB02', N'Bán hàng', N'Sài gòn'                -- Lỗi Trùng Mã (PB02 đã có)
EXEC ThemPB_Doc N'PB10', N'Nhân sự', N'Sài gòn'                 -- Thành công
GO


-- **********************************************************************
-- PHẦN 3: Phân mảnh HỖN HỢP (2 điểm)
-- Ghi chú: Chạy các SP dưới đây giả định rằng các bảng 
-- PhongBan_HH1, HH2, HH3, HH4 đã được tạo sẵn trong Database.
-- **********************************************************************

-- ==========================================================
-- Câu 6: (1 điểm) Tạo View tên DanhSachTatCaPB_HH
-- ==========================================================

-- Tạo View DanhSachTatCaPB_HH:
CREATE VIEW DanhSachTatCaPB_HH AS
    SELECT h1.MaPB, h1.TenPB, h2.ChiNhanh 
    FROM PhongBan_HH1 h1 
    JOIN PhongBan_HH2 h2 ON h1.MaPB = h2.MaPB
    UNION ALL
    SELECT h3.MaPB, h3.TenPB, h4.ChiNhanh 
    FROM PhongBan_HH3 h3 
    JOIN PhongBan_HH4 h4 ON h3.MaPB = h4.MaPB
GO

-- Test View DanhSachTatCaPB_HH:
SELECT * FROM DanhSachTatCaPB_HH
GO

-- ==========================================================
-- Câu 7: (1 điểm) Tạo stored procedure tên ThemPB_HH
-- ==========================================================

-- Tạo PROC ThemPB_HH:
CREATE PROC ThemPB_HH
@MaPB NVARCHAR(10),
@TenPB NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    IF (@MaPB IS NULL OR @TenPB IS NULL OR @ChiNhanh IS NULL)
        PRINT N'Lỗi: Không được để trống tham số!'
    ELSE IF @ChiNhanh NOT IN (N'Sài gòn', N'Hà nội')
        PRINT N'Lỗi: Chi nhánh không hợp lệ!'
    ELSE IF EXISTS (SELECT * FROM PhongBan_HH1 WHERE MaPB = @MaPB)
         OR EXISTS (SELECT * FROM PhongBan_HH3 WHERE MaPB = @MaPB)
        PRINT N'Lỗi: Mã Phòng ban đã tồn tại, không thể thêm!'
    ELSE
    BEGIN
        IF @ChiNhanh = N'Sài gòn'
        BEGIN
            INSERT INTO PhongBan_HH1 VALUES (@MaPB, @TenPB)
            INSERT INTO PhongBan_HH2 VALUES (@MaPB, @ChiNhanh)
            PRINT N'Thành công: Đã thêm vào phân mảnh Sài Gòn (HH1, HH2)!'
        END
        ELSE IF @ChiNhanh = N'Hà nội'
        BEGIN
            INSERT INTO PhongBan_HH3 VALUES (@MaPB, @TenPB)
            INSERT INTO PhongBan_HH4 VALUES (@MaPB, @ChiNhanh)
            PRINT N'Thành công: Đã thêm vào phân mảnh Hà Nội (HH3, HH4)!'
        END
    END
GO

-- Test PROC ThemPB_HH:
PRINT N'--- TEST CÂU 7 ---'
EXEC ThemPB_HH NULL, N'Quảng cáo', N'Sài gòn'               -- Lỗi NULL
EXEC ThemPB_HH N'PB11', N'Nhân sự', N'Đà Nẵng'              -- Lỗi Chi nhánh
EXEC ThemPB_HH N'PB03', N'Tiếp thị', N'Sài gòn'             -- Lỗi Trùng Mã (PB03 đã có)
EXEC ThemPB_HH N'PB11', N'Công nghệ TT', N'Sài gòn'         -- Thành công (Vào HH1, HH2)
EXEC ThemPB_HH N'PB12', N'Đào tạo', N'Hà nội'               -- Thành công (Vào HH3, HH4)
GO

------------------------HẾT-----------------------------------------