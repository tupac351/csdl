-- ============================================================
--  ĐỀ MÁY CHẴN - MÔN CƠ SỞ DỮ LIỆU NÂNG CAO
--  Sửa tên file thành: SoMay_MSSV_HoTenKhongDau_DeChan.sql
-- ============================================================

-- ============================================================
-- Câu 1: (2 điểm)
-- Tạo 2 Stored procedure phân mảnh ngang chính (PhongBan)
-- và phân mảnh ngang dẫn xuất (NhanVien)
-- ============================================================

-- Tạo Stored procedure phân mảnh bảng PhongBan:
CREATE PROC TaoPhanManhPB
AS
    SELECT * INTO PhongBanHN
    FROM PhongBan
    WHERE ChiNhanh = N'Hà nội'

    SELECT * INTO PhongBanSG
    FROM PhongBan
    WHERE ChiNhanh = N'Sài gòn'
GO

-- Exec Stored procedure phân mảnh bảng PhongBan:
EXEC dbo.TaoPhanManhPB
GO

-- Tạo Stored procedure phân mảnh bảng NhanVien:
CREATE PROC TaoPhanManhNV
AS
    SELECT * INTO NhanVienHN
    FROM NhanVien
    WHERE MaPB IN (SELECT MaPB FROM PhongBanHN)

    SELECT * INTO NhanVienSG
    FROM NhanVien
    WHERE MaPB IN (SELECT MaPB FROM PhongBanSG)
GO

-- Exec Stored procedure phân mảnh bảng NhanVien:
EXEC dbo.TaoPhanManhNV
GO


-- ============================================================
-- Câu 2: (2 điểm)
-- DS nhân viên theo tên phòng ban – Mức 1 và Mức 2
-- ============================================================

-- Tạo Stored procedure DSNhanVienMuc1 (Fragmentation Transparency):
CREATE PROC DSNhanVienMuc1
@TenPB NVARCHAR(50)
AS
    IF (@TenPB IS NULL OR @TenPB = '')
        PRINT N'Không nhập tên phòng ban!'
    ELSE IF NOT EXISTS (SELECT * FROM PhongBan WHERE TenPB = @TenPB)
        PRINT N'Không tìm thấy tên phòng ban!'
    ELSE
        SELECT nv.MaNV, nv.Ho, nv.Ten, nv.MaPB, pb.TenPB, pb.ChiNhanh
        FROM PhongBan pb
        JOIN NhanVien nv ON pb.MaPB = nv.MaPB
        WHERE pb.TenPB = @TenPB
GO

-- Exec Stored procedure DSNhanVienMuc1:
EXEC dbo.DSNhanVienMuc1 N'Thiết kế'
EXEC dbo.DSNhanVienMuc1 N'Kế toán'
EXEC dbo.DSNhanVienMuc1 N'Kỹ thuật'
EXEC dbo.DSNhanVienMuc1 NULL
GO


-- Tạo Stored procedure DSNhanVienMuc2 (Location Transparency) - BẢN ĐÃ FIX UNION:
IF OBJECT_ID('DSNhanVienMuc2', 'P') IS NOT NULL DROP PROC DSNhanVienMuc2;
GO
CREATE PROC DSNhanVienMuc2
@TenPB NVARCHAR(50)
AS
    -- Xử lý bắt lỗi
    IF (@TenPB IS NULL OR @TenPB = '')
        PRINT N'Không nhập tên phòng ban!'
    ELSE IF NOT EXISTS (SELECT * FROM PhongBanHN WHERE TenPB = @TenPB)
      AND NOT EXISTS (SELECT * FROM PhongBanSG WHERE TenPB = @TenPB)
        PRINT N'Không tìm thấy tên phòng ban!'
    
    -- Xử lý truy vấn
    ELSE 
    BEGIN
        -- Tìm ở phân mảnh Hà Nội
        SELECT nv.MaNV, nv.Ho, nv.Ten, nv.MaPB, pb.TenPB, pb.ChiNhanh
        FROM PhongBanHN pb
        JOIN NhanVienHN nv ON pb.MaPB = nv.MaPB
        WHERE pb.TenPB = @TenPB
        
        UNION ALL  -- Gom kết quả lại với nhau
        
        -- Tìm ở phân mảnh Sài Gòn
        SELECT nv.MaNV, nv.Ho, nv.Ten, nv.MaPB, pb.TenPB, pb.ChiNhanh
        FROM PhongBanSG pb
        JOIN NhanVienSG nv ON pb.MaPB = nv.MaPB
        WHERE pb.TenPB = @TenPB
    END
GO

-- Exec Stored procedure DSNhanVienMuc2:
PRINT N'--- TEST CÂU 2 MỨC 2 ---'
EXEC dbo.DSNhanVienMuc2 N'Thiết kế'
EXEC dbo.DSNhanVienMuc2 N'Kế toán'
EXEC dbo.DSNhanVienMuc2 N'Kỹ thuật'
EXEC dbo.DSNhanVienMuc2 NULL
GO


-- ============================================================
-- Câu 3: (3 điểm)
-- Thêm phòng ban – Mức 1 và Mức 2
-- ============================================================

-- Tạo Stored procedure ThemPhongBanMuc1 (Fragmentation Transparency):
CREATE PROC ThemPhongBanMuc1
@MaPB   NVARCHAR(10),
@TenPB  NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    IF @MaPB IS NULL
        PRINT N'Không thêm dữ liệu được vì không có giá trị mã PB!'
    ELSE IF @TenPB IS NULL
        PRINT N'Không thêm dữ liệu được vì không có giá trị tên PB!'
    ELSE IF @ChiNhanh IS NULL
        PRINT N'Không thêm dữ liệu được vì không có giá trị chi nhánh!'
    ELSE IF @ChiNhanh NOT IN (N'Sài gòn', N'Hà nội')
        PRINT N'Không thêm được PB vì chi nhánh không hợp lệ!'
    ELSE IF EXISTS (SELECT * FROM PhongBan WHERE MaPB = @MaPB)
        PRINT N'Không thêm dữ liệu được vì trùng mã phòng ban!'
    ELSE
        BEGIN
            INSERT INTO PhongBan VALUES (@MaPB, @TenPB, @ChiNhanh)
            PRINT N'Thêm dữ liệu thành công!'
        END
GO

-- Exec Stored procedure ThemPhongBanMuc1:
EXEC dbo.ThemPhongBanMuc1 NULL, N'Bảo hành', N'Sài gòn'
EXEC dbo.ThemPhongBanMuc1 N'PB07', N'Bảo hành', N'Sài gòn'
EXEC dbo.ThemPhongBanMuc1 N'PB08', N'Tư vấn', N'Hà nội'
EXEC dbo.ThemPhongBanMuc1 N'PB01', N'Kho vận', N'Hà nội'
EXEC dbo.ThemPhongBanMuc1 N'PB09', N'Nghiên cứu', N'Cần thơ'
GO


-- Tạo Stored procedure ThemPhongBanMuc2 (Location Transparency):
CREATE PROC ThemPhongBanMuc2
@MaPB   NVARCHAR(10),
@TenPB  NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    IF @MaPB IS NULL
        PRINT N'Không thêm dữ liệu được vì không có giá trị mã PB!'
    ELSE IF @TenPB IS NULL
        PRINT N'Không thêm dữ liệu được vì không có giá trị tên PB!'
    ELSE IF @ChiNhanh IS NULL
        PRINT N'Không thêm dữ liệu được vì không có giá trị chi nhánh!'
    ELSE IF @ChiNhanh NOT IN (N'Sài gòn', N'Hà nội')
        PRINT N'Không thêm được PB vì chi nhánh không hợp lệ!'
    ELSE IF EXISTS (SELECT * FROM PhongBanHN WHERE MaPB = @MaPB)
      OR   EXISTS (SELECT * FROM PhongBanSG WHERE MaPB = @MaPB)
        PRINT N'Không thêm dữ liệu được vì trùng mã phòng ban!'
    ELSE
        BEGIN
            IF @ChiNhanh = N'Hà nội'
                INSERT INTO PhongBanHN VALUES (@MaPB, @TenPB, @ChiNhanh)
            ELSE IF @ChiNhanh = N'Sài gòn'
                INSERT INTO PhongBanSG VALUES (@MaPB, @TenPB, @ChiNhanh)
            PRINT N'Thêm dữ liệu thành công!'
        END
GO

-- Exec Stored procedure ThemPhongBanMuc2:
EXEC dbo.ThemPhongBanMuc2 NULL, N'Bảo hành', N'Sài gòn'
EXEC dbo.ThemPhongBanMuc2 N'PB07', N'Bảo hành', N'Sài gòn'
EXEC dbo.ThemPhongBanMuc2 N'PB08', N'Tư vấn', N'Hà nội'
EXEC dbo.ThemPhongBanMuc2 N'PB01', N'Kho vận', N'Hà nội'
EXEC dbo.ThemPhongBanMuc2 N'PB09', N'Nghiên cứu', N'Cần thơ'
GO


-- ============================================================
-- Câu 4: (3 điểm)
-- Sửa phòng ban – Mức 1 và Mức 2
-- ============================================================

-- Tạo Stored procedure SuaPhongBanMuc1 (Fragmentation Transparency):
CREATE PROC SuaPhongBanMuc1
@MaPB     NVARCHAR(10),
@TenPB    NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    IF @MaPB IS NULL
        PRINT N'Không sửa dữ liệu được vì không có giá trị mã phòng ban!'
    ELSE IF @TenPB IS NULL
        PRINT N'Không sửa dữ liệu được vì không có giá trị tên phòng ban!'
    ELSE IF @ChiNhanh IS NULL
        PRINT N'Không sửa dữ liệu được vì không có giá trị chi nhánh!'
    ELSE IF @ChiNhanh NOT IN (N'Sài gòn', N'Hà nội')
        PRINT N'Không sửa dữ liệu được vì giá trị chi nhánh không hợp lệ!'
    ELSE IF NOT EXISTS (SELECT * FROM PhongBan WHERE MaPB = @MaPB)
        PRINT N'Không sửa dữ liệu được vì không tìm thấy có giá trị mã phòng ban!'
    ELSE
        BEGIN
            UPDATE PhongBan
            SET TenPB = @TenPB, ChiNhanh = @ChiNhanh
            WHERE MaPB = @MaPB
            PRINT N'Dữ liệu đã được cập nhật'
        END
GO

-- Exec Stored procedure SuaPhongBanMuc1:
EXEC dbo.SuaPhongBanMuc1 NULL, N'Thiết kế', N'Sài gòn'
EXEC dbo.SuaPhongBanMuc1 N'PB01', N'Nghiên cứu', NULL
EXEC dbo.SuaPhongBanMuc1 N'PB01', N'Nghiên cứu', N'Cần thơ'
EXEC dbo.SuaPhongBanMuc1 N'PB01', N'Nghiên cứu', N'Sài gòn'
EXEC dbo.SuaPhongBanMuc1 N'PB02', N'Phát triển', N'Hà nội'
EXEC dbo.SuaPhongBanMuc1 N'PB06', N'Tài chánh', N'Sài gòn'
EXEC dbo.SuaPhongBanMuc1 N'PB09', N'Kỹ thuật', N'Sài gòn'
GO


-- Tạo Stored procedure SuaPhongBanMuc2 (Location Transparency):
CREATE PROC SuaPhongBanMuc2
@MaPB     NVARCHAR(10),
@TenPB    NVARCHAR(50),
@ChiNhanh NVARCHAR(50)
AS
    IF @MaPB IS NULL
        PRINT N'Không sửa dữ liệu được vì không có giá trị mã phòng ban!'
    ELSE IF @TenPB IS NULL
        PRINT N'Không sửa dữ liệu được vì không có giá trị tên phòng ban!'
    ELSE IF @ChiNhanh IS NULL
        PRINT N'Không sửa dữ liệu được vì không có giá trị chi nhánh!'
    ELSE IF @ChiNhanh NOT IN (N'Sài gòn', N'Hà nội')
        PRINT N'Không sửa dữ liệu được vì giá trị chi nhánh không hợp lệ!'
    ELSE IF NOT EXISTS (SELECT * FROM PhongBanHN WHERE MaPB = @MaPB)
      AND NOT EXISTS (SELECT * FROM PhongBanSG WHERE MaPB = @MaPB)
        PRINT N'Không sửa dữ liệu được vì không tìm thấy có giá trị mã phòng ban!'
    ELSE IF EXISTS (SELECT * FROM PhongBanHN WHERE MaPB = @MaPB)
        BEGIN
            -- Phòng ban hiện đang ở phân mảnh Hà Nội
            UPDATE PhongBanHN
            SET TenPB = @TenPB, ChiNhanh = @ChiNhanh
            WHERE MaPB = @MaPB

            IF @ChiNhanh = N'Sài gòn'
                BEGIN
                    -- Dời nhân viên sang phân mảnh Sài Gòn
                    INSERT INTO NhanVienSG
                        SELECT * FROM NhanVienHN WHERE MaPB = @MaPB

                    -- Dời phòng ban sang phân mảnh Sài Gòn
                    INSERT INTO PhongBanSG
                        SELECT * FROM PhongBanHN WHERE MaPB = @MaPB

                    DELETE NhanVienHN WHERE MaPB = @MaPB
                    DELETE PhongBanHN  WHERE MaPB = @MaPB

                    PRINT N'Dữ liệu đã được cập nhật. Đã chuyển dữ liệu nhân viên từ phân mảnh NhanVienHN sang NhanVienSG. Chuyển dữ liệu từ phân mảnh PhongBanHN sang phân mảnh PhongBanSG.'
                END
            ELSE
                PRINT N'Dữ liệu đã được cập nhật tại phân mảnh PhongBanHN'
        END
    ELSE IF EXISTS (SELECT * FROM PhongBanSG WHERE MaPB = @MaPB)
        BEGIN
            -- Phòng ban hiện đang ở phân mảnh Sài Gòn
            UPDATE PhongBanSG
            SET TenPB = @TenPB, ChiNhanh = @ChiNhanh
            WHERE MaPB = @MaPB

            IF @ChiNhanh = N'Hà nội'
                BEGIN
                    -- Dời nhân viên sang phân mảnh Hà Nội
                    INSERT INTO NhanVienHN
                        SELECT * FROM NhanVienSG WHERE MaPB = @MaPB

                    -- Dời phòng ban sang phân mảnh Hà Nội
                    INSERT INTO PhongBanHN
                        SELECT * FROM PhongBanSG WHERE MaPB = @MaPB

                    DELETE NhanVienSG WHERE MaPB = @MaPB
                    DELETE PhongBanSG  WHERE MaPB = @MaPB

                    PRINT N'Dữ liệu đã được cập nhật. Đã chuyển dữ liệu nhân viên từ phân mảnh NhanVienSG sang NhanVienHN. Chuyển dữ liệu từ phân mảnh PhongBanSG sang phân mảnh PhongBanHN.'
                END
            ELSE
                PRINT N'Dữ liệu đã được cập nhật tại phân mảnh PhongBanSG'
        END
GO

-- Exec Stored procedure SuaPhongBanMuc2:
EXEC dbo.SuaPhongBanMuc2 NULL, N'Thiết kế', N'Sài gòn'
EXEC dbo.SuaPhongBanMuc2 N'PB01', N'Nghiên cứu', NULL
EXEC dbo.SuaPhongBanMuc2 N'PB01', N'Nghiên cứu', N'Cần thơ'
EXEC dbo.SuaPhongBanMuc2 N'PB01', N'Nghiên cứu', N'Sài gòn'
EXEC dbo.SuaPhongBanMuc2 N'PB02', N'Phát triển', N'Hà nội'
EXEC dbo.SuaPhongBanMuc2 N'PB06', N'Tài chánh', N'Sài gòn'
EXEC dbo.SuaPhongBanMuc2 N'PB09', N'Kỹ thuật', N'Sài gòn'
GO

-- HẾT --------------------------------------------------------
