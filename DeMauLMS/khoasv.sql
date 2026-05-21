-- 1. Tạo Stored procedure phân mảnh bảng Khoa:
IF OBJECT_ID('TaoPM_NGANG_KHOA', 'P') IS NOT NULL DROP PROC TaoPM_NGANG_KHOA;
GO
CREATE PROC TaoPM_NGANG_KHOA 
AS
    -- Xóa bảng cũ trước khi tạo bảng mới
    IF OBJECT_ID('Khoa_CS1', 'U') IS NOT NULL DROP TABLE Khoa_CS1;
    IF OBJECT_ID('Khoa_CS2', 'U') IS NOT NULL DROP TABLE Khoa_CS2;

    SELECT * INTO Khoa_CS1 FROM Khoa WHERE CoSo = N'Cơ sở 1'
    SELECT * INTO Khoa_CS2 FROM Khoa WHERE CoSo = N'Cơ sở 2'
GO

EXEC dbo.TaoPM_NGANG_KHOA
GO

-- 2. Tạo Stored procedure phân mảnh bảng Sinh Viên:
IF OBJECT_ID('TaoPM_NGANG_SV', 'P') IS NOT NULL DROP PROC TaoPM_NGANG_SV;
GO
CREATE PROC TaoPM_NGANG_SV 
AS
    -- Xóa bảng cũ trước khi tạo bảng mới
    IF OBJECT_ID('SV_CS1', 'U') IS NOT NULL DROP TABLE SV_CS1;
    IF OBJECT_ID('SV_CS2', 'U') IS NOT NULL DROP TABLE SV_CS2;

    SELECT * INTO SV_CS1 FROM SinhVien WHERE MaKhoa IN (SELECT MaKhoa FROM Khoa_CS1)
    SELECT * INTO SV_CS2 FROM SinhVien WHERE MaKhoa IN (SELECT MaKhoa FROM Khoa_CS2) -- Đã sửa lỗi dư chữ K
GO

EXEC dbo.TaoPM_NGANG_SV
GO

IF OBJECT_ID('DSSinhVienMuc1', 'P') IS NOT NULL DROP PROC DSSinhVienMuc1;
GO
CREATE PROC DSSinhVienMuc1 
@TenKhoa NVARCHAR(50)
AS
    -- 1. Bắt lỗi ngoại lệ
    IF (@TenKhoa IS NULL)
        PRINT N'Không nhập tên Khoa!'
    ELSE IF NOT EXISTS (SELECT * FROM Khoa WHERE TenKhoa = @TenKhoa)
        PRINT N'Không tìm thấy tên Khoa!'
    
    -- 2. Nếu không lỗi thì SELECT (Join bảng gốc)
    ELSE
    BEGIN
        SELECT sv.MaSV, sv.HoTen, k.MaKhoa, k.TenKhoa
        FROM Khoa k 
        JOIN SinhVien sv ON k.MaKhoa = sv.MaKhoa
        WHERE k.TenKhoa = @TenKhoa
    END
GO

-- CHẠY TEST MỨC 1:
PRINT N'--- TEST CÂU 2 - MỨC 1 ---'
EXEC DSSinhVienMuc1 N'Công nghệ thông tin'   -- Sẽ hiện bảng kết quả
EXEC DSSinhVienMuc1 N'Ngoại ngữ'             -- Sẽ hiện bảng kết quả
EXEC DSSinhVienMuc1 N'Y dược'                -- Hiện báo lỗi không tìm thấy
EXEC DSSinhVienMuc1 NULL                     -- Hiện báo lỗi NULL
GO

IF OBJECT_ID('DSSinhVienMuc2', 'P') IS NOT NULL DROP PROC DSSinhVienMuc2;
GO
CREATE PROC DSSinhVienMuc2 
@TenKhoa NVARCHAR(50)
AS
    -- 1. Bắt lỗi ngoại lệ (Phải tìm ở cả 2 mảnh Cơ sở 1 và 2)
    IF (@TenKhoa IS NULL)
        PRINT N'Không nhập tên Khoa!'
    ELSE IF NOT EXISTS (SELECT * FROM Khoa_CS1 WHERE TenKhoa = @TenKhoa)
        AND NOT EXISTS (SELECT * FROM Khoa_CS2 WHERE TenKhoa = @TenKhoa)
        PRINT N'Không tìm thấy tên Khoa!'
    
    -- 2. Nếu không lỗi thì SELECT kết hợp UNION ALL
    ELSE
    BEGIN
        -- Tìm ở Cơ sở 1
        SELECT sv.MaSV, sv.HoTen, k.MaKhoa, k.TenKhoa
        FROM Khoa_CS1 k 
        JOIN SV_CS1 sv ON k.MaKhoa = sv.MaKhoa
        WHERE k.TenKhoa = @TenKhoa
        
        UNION ALL  -- Ghép nối với kết quả ở dưới
        
        -- Tìm ở Cơ sở 2
        SELECT sv.MaSV, sv.HoTen, k.MaKhoa, k.TenKhoa
        FROM Khoa_CS2 k 
        JOIN SV_CS2 sv ON k.MaKhoa = sv.MaKhoa
        WHERE k.TenKhoa = @TenKhoa
    END
GO

-- CHẠY TEST MỨC 2:
PRINT N'--- TEST CÂU 2 - MỨC 2 ---'
EXEC DSSinhVienMuc2 N'Công nghệ thông tin'   
EXEC DSSinhVienMuc2 N'Ngoại ngữ'             
EXEC DSSinhVienMuc2 N'Y dược'                
EXEC DSSinhVienMuc2 NULL                     
GO

-- ==========================================================
-- Câu 3: Thêm Khoa
-- ==========================================================
-- 1. TẠO MỨC 1:
IF OBJECT_ID('ThemKhoaMuc1', 'P') IS NOT NULL DROP PROC ThemKhoaMuc1;
GO
CREATE PROC ThemKhoaMuc1
@MaKhoa NVARCHAR(10),
@TenKhoa NVARCHAR(50),
@CoSo NVARCHAR(50)
AS
    IF (@MaKhoa IS NULL OR @TenKhoa IS NULL OR @CoSo IS NULL)
        PRINT N'Không có giá trị mã Khoa!' -- Hoặc báo thiếu thông tin
    ELSE IF @CoSo NOT IN (N'Cơ sở 1', N'Cơ sở 2')
        PRINT N'Cơ sở không hợp lệ!'
    ELSE IF EXISTS (SELECT * FROM Khoa WHERE MaKhoa = @MaKhoa)
        PRINT N'Trùng mã Khoa!'
    ELSE
    BEGIN
        INSERT INTO Khoa VALUES (@MaKhoa, @TenKhoa, @CoSo)
        PRINT N'Thêm dữ liệu thành công!'
    END
GO

-- TEST CÂU 3 MỨC 1:
PRINT N'--- TEST CÂU 3 MỨC 1 ---'
EXEC ThemKhoaMuc1 NULL, N'Kinh tế', N'Cơ sở 1'
EXEC ThemKhoaMuc1 N'K05', N'Du lịch', N'Cơ sở 3'
EXEC ThemKhoaMuc1 N'K01', N'Toán học', N'Cơ sở 1'
EXEC ThemKhoaMuc1 N'K98', N'Kinh tế', N'Cơ sở 1'
GO

-- 2. TẠO MỨC 2:
IF OBJECT_ID('ThemKhoaMuc2', 'P') IS NOT NULL DROP PROC ThemKhoaMuc2;
GO
CREATE PROC ThemKhoaMuc2
@MaKhoa NVARCHAR(10),
@TenKhoa NVARCHAR(50),
@CoSo NVARCHAR(50)
AS
    IF (@MaKhoa IS NULL OR @TenKhoa IS NULL OR @CoSo IS NULL)
        PRINT N'Không có giá trị mã Khoa!'
    ELSE IF @CoSo NOT IN (N'Cơ sở 1', N'Cơ sở 2')
        PRINT N'Cơ sở không hợp lệ!'
    ELSE IF EXISTS (SELECT * FROM Khoa_CS1 WHERE MaKhoa = @MaKhoa)
         OR EXISTS (SELECT * FROM Khoa_CS2 WHERE MaKhoa = @MaKhoa)
        PRINT N'Trùng mã Khoa!'
    ELSE
    BEGIN
        IF @CoSo = N'Cơ sở 1'
            INSERT INTO Khoa_CS1 VALUES (@MaKhoa, @TenKhoa, @CoSo)
        ELSE IF @CoSo = N'Cơ sở 2'
            INSERT INTO Khoa_CS2 VALUES (@MaKhoa, @TenKhoa, @CoSo)
        PRINT N'Thêm dữ liệu thành công!'
    END
GO

-- TEST CÂU 3 MỨC 2:
PRINT N'--- TEST CÂU 3 MỨC 2 ---'
EXEC ThemKhoaMuc2 NULL, N'Kinh tế', N'Cơ sở 1'
EXEC ThemKhoaMuc2 N'K05', N'Du lịch', N'Cơ sở 3'
EXEC ThemKhoaMuc2 N'K01', N'Toán học', N'Cơ sở 1'
-- Dùng K99 để không trùng với K98 đã thêm ở Mức 1
EXEC ThemKhoaMuc2 N'K99', N'Toán học', N'Cơ sở 2'
GO

-- ==========================================================
-- Câu 4: Sửa Khoa và Dời dữ liệu
-- ==========================================================
-- 1. TẠO MỨC 1:
IF OBJECT_ID('SuaKhoaMuc1', 'P') IS NOT NULL DROP PROC SuaKhoaMuc1;
GO
CREATE PROC SuaKhoaMuc1
@MaKhoa NVARCHAR(10),
@TenKhoa NVARCHAR(50),
@CoSo NVARCHAR(50)
AS
    IF (@MaKhoa IS NULL)
        PRINT N'Không có mã Khoa!'
    ELSE IF (@CoSo IS NULL)
        PRINT N'Không có giá trị cơ sở!'
    ELSE IF @CoSo NOT IN (N'Cơ sở 1', N'Cơ sở 2')
        PRINT N'Cơ sở không hợp lệ!'
    ELSE IF NOT EXISTS (SELECT * FROM Khoa WHERE MaKhoa = @MaKhoa)
        PRINT N'Không tìm thấy mã Khoa!'
    ELSE
    BEGIN
        UPDATE Khoa SET TenKhoa = @TenKhoa, CoSo = @CoSo WHERE MaKhoa = @MaKhoa
        PRINT N'Đã sửa dữ liệu thành công.'
    END
GO

-- TEST CÂU 4 MỨC 1:
PRINT N'--- TEST CÂU 4 MỨC 1 ---'
EXEC SuaKhoaMuc1 NULL, N'Khoa ABC', N'Cơ sở 1'
EXEC SuaKhoaMuc1 N'K01', N'Khoa ABC', NULL
EXEC SuaKhoaMuc1 N'K999', N'Khoa ABC', N'Cơ sở 1'
EXEC SuaKhoaMuc1 N'K01', N'CNTT Tiên tiến', N'Cơ sở 1'
GO

-- 2. TẠO MỨC 2:
IF OBJECT_ID('SuaKhoaMuc2', 'P') IS NOT NULL DROP PROC SuaKhoaMuc2;
GO
CREATE PROC SuaKhoaMuc2
@MaKhoa NVARCHAR(10),
@TenKhoa NVARCHAR(50),
@CoSo NVARCHAR(50)
AS
    IF (@MaKhoa IS NULL)
        PRINT N'Không có mã Khoa!'
    ELSE IF (@CoSo IS NULL)
        PRINT N'Không có giá trị cơ sở!'
    ELSE IF @CoSo NOT IN (N'Cơ sở 1', N'Cơ sở 2')
        PRINT N'Cơ sở không hợp lệ!'
    ELSE IF NOT EXISTS (SELECT * FROM Khoa_CS1 WHERE MaKhoa = @MaKhoa)
         AND NOT EXISTS (SELECT * FROM Khoa_CS2 WHERE MaKhoa = @MaKhoa)
        PRINT N'Không tìm thấy mã Khoa!'
    
    -- TRƯỜNG HỢP A: KHOA ĐANG Ở CƠ SỞ 1
    ELSE IF EXISTS (SELECT * FROM Khoa_CS1 WHERE MaKhoa = @MaKhoa)
    BEGIN
        -- Cập nhật dữ liệu tại chỗ cũ trước
        UPDATE Khoa_CS1 SET TenKhoa = @TenKhoa, CoSo = @CoSo WHERE MaKhoa = @MaKhoa
        
        -- Nếu đổi sang Cơ sở 2 thì dời
        IF @CoSo = N'Cơ sở 2'
        BEGIN
            -- 1. Copy Bố sang chỗ mới
            INSERT INTO Khoa_CS2 SELECT * FROM Khoa_CS1 WHERE MaKhoa = @MaKhoa
            -- 2. Copy Con sang chỗ mới
            INSERT INTO SV_CS2 SELECT * FROM SV_CS1 WHERE MaKhoa = @MaKhoa
            -- 3. Xóa Con ở chỗ cũ
            DELETE FROM SV_CS1 WHERE MaKhoa = @MaKhoa
            -- 4. Xóa Bố ở chỗ cũ
            DELETE FROM Khoa_CS1 WHERE MaKhoa = @MaKhoa
            
            PRINT N'Đã sửa thành công. Đã dời dữ liệu Khoa và Sinh viên từ Cơ sở 1 sang Cơ sở 2.'
        END
        ELSE
            PRINT N'Đã sửa dữ liệu thành công.'
    END

    -- TRƯỜNG HỢP B: KHOA ĐANG Ở CƠ SỞ 2
    ELSE IF EXISTS (SELECT * FROM Khoa_CS2 WHERE MaKhoa = @MaKhoa)
    BEGIN
        -- Cập nhật dữ liệu tại chỗ cũ trước
        UPDATE Khoa_CS2 SET TenKhoa = @TenKhoa, CoSo = @CoSo WHERE MaKhoa = @MaKhoa
        
        -- Nếu đổi sang Cơ sở 1 thì dời
        IF @CoSo = N'Cơ sở 1'
        BEGIN
            -- 1. Copy Bố sang chỗ mới
            INSERT INTO Khoa_CS1 SELECT * FROM Khoa_CS2 WHERE MaKhoa = @MaKhoa
            -- 2. Copy Con sang chỗ mới
            INSERT INTO SV_CS1 SELECT * FROM SV_CS2 WHERE MaKhoa = @MaKhoa
            -- 3. Xóa Con ở chỗ cũ
            DELETE FROM SV_CS2 WHERE MaKhoa = @MaKhoa
            -- 4. Xóa Bố ở chỗ cũ
            DELETE FROM Khoa_CS2 WHERE MaKhoa = @MaKhoa
            
            PRINT N'Đã sửa thành công. Đã dời dữ liệu Khoa và Sinh viên từ Cơ sở 2 sang Cơ sở 1.'
        END
        ELSE
            PRINT N'Đã sửa dữ liệu thành công.'
    END
GO

-- TEST CÂU 4 MỨC 2:
PRINT N'--- TEST CÂU 4 MỨC 2 ---'
EXEC SuaKhoaMuc2 NULL, N'Khoa ABC', N'Cơ sở 1'
EXEC SuaKhoaMuc2 N'K01', N'Khoa ABC', NULL
EXEC SuaKhoaMuc2 N'K999', N'Khoa ABC', N'Cơ sở 1'
EXEC SuaKhoaMuc2 N'K01', N'CNTT Tiên tiến', N'Cơ sở 1' -- Sửa tại chỗ, không dời
EXEC SuaKhoaMuc2 N'K02', N'Ngoại ngữ mới', N'Cơ sở 1'  -- Có dời từ CS2 sang CS1
GO

-- ==========================================================
-- Câu 5: Xóa Sinh Viên
-- ==========================================================
-- 1. TẠO MỨC 1:
IF OBJECT_ID('XoaSVMuc1', 'P') IS NOT NULL DROP PROC XoaSVMuc1;
GO
CREATE PROC XoaSVMuc1
@MaSV NVARCHAR(10)
AS
    IF (@MaSV IS NULL)
        PRINT N'Không nhập mã sinh viên!'
    ELSE IF NOT EXISTS (SELECT * FROM SinhVien WHERE MaSV = @MaSV)
        PRINT N'Không tìm thấy sinh viên để xóa!'
    ELSE
    BEGIN
        DELETE FROM SinhVien WHERE MaSV = @MaSV
        PRINT N'Xóa và báo thành công'
    END
GO

-- TEST CÂU 5 MỨC 1:
PRINT N'--- TEST CÂU 5 MỨC 1 ---'
EXEC XoaSVMuc1 N'SV001'
EXEC XoaSVMuc1 N'SV999'
EXEC XoaSVMuc1 NULL
GO

-- 2. TẠO MỨC 2:
IF OBJECT_ID('XoaSVMuc2', 'P') IS NOT NULL DROP PROC XoaSVMuc2;
GO
CREATE PROC XoaSVMuc2
@MaSV NVARCHAR(10)
AS
    IF (@MaSV IS NULL)
        PRINT N'Không nhập mã sinh viên!'
    ELSE IF NOT EXISTS (SELECT * FROM SV_CS1 WHERE MaSV = @MaSV)
         AND NOT EXISTS (SELECT * FROM SV_CS2 WHERE MaSV = @MaSV)
        PRINT N'Không tìm thấy sinh viên để xóa!'
    ELSE
    BEGIN
        IF EXISTS (SELECT * FROM SV_CS1 WHERE MaSV = @MaSV)
            DELETE FROM SV_CS1 WHERE MaSV = @MaSV
        ELSE IF EXISTS (SELECT * FROM SV_CS2 WHERE MaSV = @MaSV)
            DELETE FROM SV_CS2 WHERE MaSV = @MaSV
        
        PRINT N'Xóa và báo thành công'
    END
GO

-- TEST CÂU 5 MỨC 2:
PRINT N'--- TEST CÂU 5 MỨC 2 ---'
-- (SV001 đã bị xóa ở mức 1 nên dùng SV002 để test thành công ở Mức 2 nhé)
EXEC XoaSVMuc2 N'SV002'
EXEC XoaSVMuc2 N'SV999'
EXEC XoaSVMuc2 NULL
GO
