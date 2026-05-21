----------------------ĐỀ THI MÁY CHẲN-----------
MÔN: CSDLPT
MSSV:
HỌ TÊN SV:

-----------------------------------------------------------------------

--PHẦN 1: Phân mảnh ngang chính và phân mảnh ngang dẫn xuất (4 điểm)

--Câu 1: (2 điểm) Hãy viết 2 Stored procedure tên: 
--(SV TỰ ĐẶT TÊN CHO CÁC PHÂN MẢNH NGANG)

-- Tạo PROC TaoPM_Ngang_PhongBan:
CREATE PROC TaoPM_Ngang_PhongBan AS
    SELECT * INTO PhongBan_CT FROM PhongBan WHERE ChiNhanh = N'Cần Thơ'
    SELECT * INTO PhongBan_DN FROM PhongBan WHERE ChiNhanh = N'Đà Nẵng'
GO

-- Test PROC TaoPM_Ngang_PhongBan:
EXEC dbo.TaoPM_Ngang_PhongBan
GO

-- Tạo PROC TaoPM_Ngang_NhanVien:
CREATE PROC TaoPM_Ngang_NhanVien AS
    SELECT * INTO NhanVien_CT FROM NhanVien WHERE MaPB IN (SELECT MaPB FROM PhongBan_CT)
    SELECT * INTO NhanVien_DN FROM NhanVien WHERE MaPB IN (SELECT MaPB FROM PhongBan_DN)
    PRINT N'Đã tạo 2 phân mảnh ngang dẫn xuất cho NhanVien'
GO

-- Test PROC TaoPM_Ngang_NhanVien:
EXEC dbo.TaoPM_Ngang_NhanVien
GO


Câu 2: (2 điểm) Tạo stored procedure tên SuaPB_Ngang:

-- Tạo PROC SuaPB_Ngang:
CREATE PROC SuaPB_Ngang
@MaPB     NVARCHAR(10),
@TenPB    NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    -- 1. Bắt lỗi ngoại lệ
    IF (@MaPB IS NULL OR @TenPB IS NULL OR @ChiNhanh IS NULL)
        PRINT N'Lỗi: Không được để trống Mã PB, Tên PB hoặc Chi Nhánh!'
    ELSE IF @ChiNhanh NOT IN (N'Cần Thơ', N'Đà Nẵng')
        PRINT N'Lỗi: Chi nhánh không hợp lệ (Chỉ nhận Cần Thơ hoặc Đà Nẵng)!'
    ELSE IF NOT EXISTS (SELECT * FROM PhongBan_CT WHERE MaPB = @MaPB)
        AND NOT EXISTS (SELECT * FROM PhongBan_DN WHERE MaPB = @MaPB)
        PRINT N'Lỗi: Không tìm thấy Mã phòng ban để sửa!'
    
    -- 2. Xử lý update và dời mảnh
    ELSE IF EXISTS (SELECT * FROM PhongBan_CT WHERE MaPB = @MaPB)
        BEGIN
            -- Đang ở Cần Thơ
            UPDATE PhongBan_CT
            SET TenPB = @TenPB, ChiNhanh = @ChiNhanh
            WHERE MaPB = @MaPB

            IF @ChiNhanh = N'Đà Nẵng'
            BEGIN
                -- Dời dữ liệu Phòng Ban
                INSERT INTO PhongBan_DN SELECT * FROM PhongBan_CT WHERE MaPB = @MaPB
                DELETE PhongBan_CT WHERE MaPB = @MaPB
                
                -- Dời dữ liệu Nhân Viên (Dẫn xuất)
                INSERT INTO NhanVien_DN SELECT * FROM NhanVien_CT WHERE MaPB = @MaPB
                DELETE NhanVien_CT WHERE MaPB = @MaPB

                PRINT N'Thành công: Đã cập nhật và dời phòng ban cùng nhân viên từ Cần Thơ sang Đà Nẵng!'
            END
            ELSE
                PRINT N'Thành công: Đã cập nhật dữ liệu tại phân mảnh Cần Thơ!'
        END
    ELSE IF EXISTS (SELECT * FROM PhongBan_DN WHERE MaPB = @MaPB)
        BEGIN
            -- Đang ở Đà Nẵng
            UPDATE PhongBan_DN
            SET TenPB = @TenPB, ChiNhanh = @ChiNhanh
            WHERE MaPB = @MaPB

            IF @ChiNhanh = N'Cần Thơ'
            BEGIN
                -- Dời dữ liệu Phòng Ban
                INSERT INTO PhongBan_CT SELECT * FROM PhongBan_DN WHERE MaPB = @MaPB
                DELETE PhongBan_DN WHERE MaPB = @MaPB
                
                -- Dời dữ liệu Nhân Viên (Dẫn xuất)
                INSERT INTO NhanVien_CT SELECT * FROM NhanVien_DN WHERE MaPB = @MaPB
                DELETE NhanVien_DN WHERE MaPB = @MaPB

                PRINT N'Thành công: Đã cập nhật và dời phòng ban cùng nhân viên từ Đà Nẵng sang Cần Thơ!'
            END
            ELSE
                PRINT N'Thành công: Đã cập nhật dữ liệu tại phân mảnh Đà Nẵng!'
        END
GO

-- Test PROC SuaPB_Ngang:
PRINT N'--- TEST CÂU 2 ---'
-- Báo lỗi: NULL
EXEC SuaPB_Ngang NULL, N'Kế toán', N'Cần Thơ'
-- Báo lỗi: Sai chi nhánh
EXEC SuaPB_Ngang N'PB01', N'Nhân sự', N'Sài Gòn'
-- Báo lỗi: Không tìm thấy
EXEC SuaPB_Ngang N'PB99', N'Nhân sự', N'Cần Thơ'
-- Thành công: Sửa tên, không đổi chi nhánh (Giả sử PB01 đang ở Cần Thơ)
EXEC SuaPB_Ngang N'PB01', N'Phòng Kinh Doanh', N'Cần Thơ'
-- Thành công: Sửa tên và DỜI chi nhánh sang Đà Nẵng
EXEC SuaPB_Ngang N'PB01', N'Phòng Kinh Doanh', N'Đà Nẵng'
GO

------------------------------------------------------------------

PHẦN 2: Phân mảnh dọc (4 điểm)

Câu 3: (1 điểm) Hãy viết Stored procedure tên: TaoPM_Doc_PhongBan:
PhongBan_Doc1(MaPB, TenPB)
PhongBan_Doc2(MaPB, ChiNhanh)

-- Tạo PROC TaoPM_Doc_PhongBan:
CREATE PROC TaoPM_Doc_PhongBan
AS
--    IF OBJECT_ID('PhongBan_Doc1', 'U') IS NOT NULL DROP TABLE PhongBan_Doc1;
--    IF OBJECT_ID('PhongBan_Doc2', 'U') IS NOT NULL DROP TABLE PhongBan_Doc2;

    SELECT MaPB, TenPB INTO PhongBan_Doc1 FROM PhongBan;
    SELECT MaPB, ChiNhanh INTO PhongBan_Doc2 FROM PhongBan;
GO


-- Test PROC TaoPM_Doc_PhongBan:
EXEC dbo.TaoPM_Doc_PhongBan
GO

-Câu 4: (1 điểm) Hãy viết Stored procedure tên: XemPB_Doc:

-- Tạo PROC XemPB_Doc:
CREATE PROC XemPB_Doc
AS
    SELECT d1.MaPB, d1.TenPB, d2.ChiNhanh
    FROM PhongBan_Doc1 d1
    JOIN PhongBan_Doc2 d2 ON d1.MaPB = d2.MaPB
    WHERE d1.TenPB IN (N'Tiếp thị', N'Sản xuất')
GO


-- Test PROC XemPB_Doc:
EXEC dbo.XemPB_Doc
GO

Câu 5: (2 điểm) Tạo stored procedure tên SuaPB_Doc:

-- Tạo PROC SuaPB_Doc:
CREATE PROC SuaPB_Doc
@MaPB     NVARCHAR(10),
@TenPB    NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    IF (@MaPB IS NULL OR @TenPB IS NULL OR @ChiNhanh IS NULL)
        PRINT N'Lỗi: Không được để trống Mã PB, Tên PB hoặc Chi Nhánh!'
    ELSE IF @ChiNhanh NOT IN (N'Cần Thơ', N'Đà Nẵng')
        PRINT N'Lỗi: Chi nhánh không hợp lệ (Chỉ nhận Cần Thơ hoặc Đà Nẵng)!'
    ELSE IF NOT EXISTS (SELECT * FROM PhongBan_Doc1 WHERE MaPB = @MaPB)
        PRINT N'Lỗi: Không tìm thấy Mã phòng ban để sửa!'
    ELSE
        BEGIN
            -- Cập nhật vào Doc1 (Chứa TenPB)
            UPDATE PhongBan_Doc1
            SET TenPB = @TenPB
            WHERE MaPB = @MaPB

            -- Cập nhật vào Doc2 (Chứa ChiNhanh)
            UPDATE PhongBan_Doc2
            SET ChiNhanh = @ChiNhanh
            WHERE MaPB = @MaPB

            PRINT N'Thành công: Đã cập nhật dữ liệu trên cả 2 phân mảnh dọc!'
        END
GO

-- Test PROC SuaPB_Doc:
PRINT N'--- TEST CÂU 5 ---'
-- Báo lỗi NULL
EXEC SuaPB_Doc N'PB02', NULL, N'Cần Thơ'
-- Báo lỗi chi nhánh sai
EXEC SuaPB_Doc N'PB02', N'Tiếp thị', N'Hà Nội'
-- Báo lỗi không tìm thấy
EXEC SuaPB_Doc N'PB99', N'Tiếp thị', N'Đà Nẵng'
-- Sửa thành công
EXEC SuaPB_Doc N'PB02', N'Phòng Marketing', N'Đà Nẵng'
GO

---------------------------------------------------


PHẦN 3: Phân mảnh HỖN HỢP (2 điểm)

Câu 6: (1 điểm) Tạo View tên DanhSachTatCaPB_HH:

-- Tạo View DanhSachTatCaPB_HH:


-- Test View DanhSachTatCaPB_HH:


Câu 7: (1 điểm) Tạo stored procedure tên SuaPB_HH:

-- Tạo PROC SuaPB_HH:


-- Test PROC SuaPB_HH:


--ĐỂ CÓ ĐIỂM, CÁC EM NHỚ LƯU FILE SQL NÀY VÀO Ổ S:\
------------------------HẾT-----------------------------------------

