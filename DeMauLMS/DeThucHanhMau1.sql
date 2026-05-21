--Mã số sinh viên: 
--Họ tên sinh viên: 
--Số máy tính:		
--Chú ý: cuối giờ nộp file .sql này (MSSV_HoTenKhongDau_SoMay.sql) vào ổ Z:\

-- ======================================================================
-- CÂU 1: TẠO PHÂN MẢNH
-- ======================================================================
-- Tạo Stored procedure phân mảnh bảng NXB:
IF OBJECT_ID('TaoPhanManhNXB', 'P') IS NOT NULL DROP PROC TaoPhanManhNXB;
GO
CREATE PROC TaoPhanManhNXB
AS
	IF OBJECT_ID('NXB_TuNhan', 'U') IS NOT NULL DROP TABLE NXB_TuNhan;
	IF OBJECT_ID('NXB_NhaNuoc', 'U') IS NOT NULL DROP TABLE NXB_NhaNuoc;

	SELECT * INTO NXB_TuNhan FROM NhaXuatBan WHERE LoaiHinh = N'Tư nhân'
	SELECT * INTO NXB_NhaNuoc FROM NhaXuatBan WHERE LoaiHinh = N'Nhà nước'
GO
-- Exec:
EXEC TaoPhanManhNXB
GO

-- Tạo Stored procedure phân mảnh bảng Sách:
IF OBJECT_ID('TaoPhanManhSach', 'P') IS NOT NULL DROP PROC TaoPhanManhSach;
GO
CREATE PROC TaoPhanManhSach
AS
	IF OBJECT_ID('Sach_TuNhan', 'U') IS NOT NULL DROP TABLE Sach_TuNhan;
	IF OBJECT_ID('Sach_NhaNuoc', 'U') IS NOT NULL DROP TABLE Sach_NhaNuoc;

	SELECT * INTO Sach_TuNhan FROM Sach WHERE MaNXB IN (SELECT MaNXB FROM NXB_TuNhan)
	SELECT * INTO Sach_NhaNuoc FROM Sach WHERE MaNXB IN (SELECT MaNXB FROM NXB_NhaNuoc)
GO
-- Exec:
EXEC TaoPhanManhSach
GO


-- ======================================================================
-- CÂU 2: LẬP DANH SÁCH SÁCH THEO TÊN NXB
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('DSSachMuc1', 'P') IS NOT NULL DROP PROC DSSachMuc1;
GO
CREATE PROC DSSachMuc1 @TenNXB NVARCHAR(50)
AS
	SELECT s.MaSach, s.TuaSach, n.MaNXB, n.TenNXB
	FROM NhaXuatBan n JOIN Sach s ON n.MaNXB = s.MaNXB
	WHERE n.TenNXB = @TenNXB
GO
PRINT N'--- TEST CÂU 2 - MỨC 1 ---'
EXEC DSSachMuc1 N'Giáo dục'
GO

-- Mức 2:
IF OBJECT_ID('DSSachMuc2', 'P') IS NOT NULL DROP PROC DSSachMuc2;
GO
CREATE PROC DSSachMuc2 @TenNXB NVARCHAR(50)
AS
	-- Phân mảnh ngang theo Loại Hình, nên tìm theo Tên NXB phải gom (UNION) cả 2 bảng
	SELECT s.MaSach, s.TuaSach, n.MaNXB, n.TenNXB
	FROM NXB_TuNhan n JOIN Sach_TuNhan s ON n.MaNXB = s.MaNXB
	WHERE n.TenNXB = @TenNXB
	UNION
	SELECT s.MaSach, s.TuaSach, n.MaNXB, n.TenNXB
	FROM NXB_NhaNuoc n JOIN Sach_NhaNuoc s ON n.MaNXB = s.MaNXB
	WHERE n.TenNXB = @TenNXB
GO
PRINT N'--- TEST CÂU 2 - MỨC 2 ---'
EXEC DSSachMuc2 N'Giáo dục'
GO


-- ======================================================================
-- CÂU 3: THÊM NXB
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('ThemNXBMuc1', 'P') IS NOT NULL DROP PROC ThemNXBMuc1;
GO
CREATE PROC ThemNXBMuc1 @MaNXB NVARCHAR(10), @TenNXB NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF NOT EXISTS (SELECT * FROM NhaXuatBan WHERE MaNXB = @MaNXB)
	BEGIN
		INSERT INTO NhaXuatBan VALUES (@MaNXB, @TenNXB, @LoaiHinh)
		PRINT N'Thêm thành công mức 1!'
	END
GO
PRINT N'--- TEST CÂU 3 - MỨC 1 ---'
EXEC ThemNXBMuc1 N'NXB10', N'Tương lai', N'Tư nhân'
EXEC ThemNXBMuc1 N'NXB11', N'Giáo dục', N'Nhà nước'
GO

-- Mức 2:
IF OBJECT_ID('ThemNXBMuc2', 'P') IS NOT NULL DROP PROC ThemNXBMuc2;
GO
CREATE PROC ThemNXBMuc2 @MaNXB NVARCHAR(10), @TenNXB NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF NOT EXISTS (SELECT * FROM NXB_TuNhan WHERE MaNXB = @MaNXB) 
	   AND NOT EXISTS (SELECT * FROM NXB_NhaNuoc WHERE MaNXB = @MaNXB)
	BEGIN
		IF @LoaiHinh = N'Tư nhân'
			INSERT INTO NXB_TuNhan VALUES (@MaNXB, @TenNXB, @LoaiHinh)
		ELSE IF @LoaiHinh = N'Nhà nước'
			INSERT INTO NXB_NhaNuoc VALUES (@MaNXB, @TenNXB, @LoaiHinh)
		PRINT N'Thêm thành công mức 2!'
	END
GO
PRINT N'--- TEST CÂU 3 - MỨC 2 ---'
-- Thay đổi mã để test không bị trùng khóa
EXEC ThemNXBMuc2 N'NXB10_M2', N'Tương lai', N'Tư nhân'
EXEC ThemNXBMuc2 N'NXB11_M2', N'Giáo dục', N'Nhà nước'
GO


-- ======================================================================
-- CÂU 4: SỬA NXB (CÓ XỬ LÝ DỜI DỮ LIỆU BỐ - CON)
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('SuaNXBMuc1', 'P') IS NOT NULL DROP PROC SuaNXBMuc1;
GO
CREATE PROC SuaNXBMuc1 @MaNXB NVARCHAR(10), @TenNXB NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF EXISTS (SELECT * FROM NhaXuatBan WHERE MaNXB = @MaNXB)
	BEGIN
		UPDATE NhaXuatBan SET TenNXB = @TenNXB, LoaiHinh = @LoaiHinh WHERE MaNXB = @MaNXB
		PRINT N'Sửa thành công mức 1!'
	END
GO
PRINT N'--- TEST CÂU 4 - MỨC 1 ---'
EXEC SuaNXBMuc1 N'NXB10', N'Thành công', N'Nhà nước'
EXEC SuaNXBMuc1 N'NXB11', N'Đất Việt', N'Tư nhân'
GO

-- Mức 2:
IF OBJECT_ID('SuaNXBMuc2', 'P') IS NOT NULL DROP PROC SuaNXBMuc2;
GO
CREATE PROC SuaNXBMuc2 @MaNXB NVARCHAR(10), @TenNXB NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF EXISTS (SELECT * FROM NXB_TuNhan WHERE MaNXB = @MaNXB)
	BEGIN
		UPDATE NXB_TuNhan SET TenNXB = @TenNXB, LoaiHinh = @LoaiHinh WHERE MaNXB = @MaNXB
		IF @LoaiHinh = N'Nhà nước'
		BEGIN
			-- Dời Bố sang trước, Con sang sau. Dọn Con chỗ cũ trước, dọn Bố chỗ cũ sau.
			INSERT INTO NXB_NhaNuoc SELECT * FROM NXB_TuNhan WHERE MaNXB = @MaNXB
			INSERT INTO Sach_NhaNuoc SELECT * FROM Sach_TuNhan WHERE MaNXB = @MaNXB
			DELETE FROM Sach_TuNhan WHERE MaNXB = @MaNXB
			DELETE FROM NXB_TuNhan WHERE MaNXB = @MaNXB
			PRINT N'Đã dời NXB và Sách từ Tư nhân sang Nhà nước!'
		END
	END
	ELSE IF EXISTS (SELECT * FROM NXB_NhaNuoc WHERE MaNXB = @MaNXB)
	BEGIN
		UPDATE NXB_NhaNuoc SET TenNXB = @TenNXB, LoaiHinh = @LoaiHinh WHERE MaNXB = @MaNXB
		IF @LoaiHinh = N'Tư nhân'
		BEGIN
			INSERT INTO NXB_TuNhan SELECT * FROM NXB_NhaNuoc WHERE MaNXB = @MaNXB
			INSERT INTO Sach_TuNhan SELECT * FROM Sach_NhaNuoc WHERE MaNXB = @MaNXB
			DELETE FROM Sach_NhaNuoc WHERE MaNXB = @MaNXB
			DELETE FROM NXB_NhaNuoc WHERE MaNXB = @MaNXB
			PRINT N'Đã dời NXB và Sách từ Nhà nước sang Tư nhân!'
		END
	END
GO
PRINT N'--- TEST CÂU 4 - MỨC 2 ---'
EXEC SuaNXBMuc2 N'NXB10_M2', N'Thành công', N'Nhà nước'
EXEC SuaNXBMuc2 N'NXB11_M2', N'Đất Việt', N'Tư nhân'
GO


-- ======================================================================
-- CÂU 5: XÓA SÁCH
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('XoaSachMuc1', 'P') IS NOT NULL DROP PROC XoaSachMuc1;
GO
CREATE PROC XoaSachMuc1 @MaSach NVARCHAR(10)
AS
	DELETE FROM Sach WHERE MaSach = @MaSach
	PRINT N'Đã xóa sách Mức 1'
GO
PRINT N'--- TEST CÂU 5 - MỨC 1 ---'
EXEC XoaSachMuc1 N'S004'
EXEC XoaSachMuc1 N'S005'
GO

-- Mức 2:
IF OBJECT_ID('XoaSachMuc2', 'P') IS NOT NULL DROP PROC XoaSachMuc2;
GO
CREATE PROC XoaSachMuc2 @MaSach NVARCHAR(10)
AS
	IF EXISTS (SELECT * FROM Sach_TuNhan WHERE MaSach = @MaSach)
		DELETE FROM Sach_TuNhan WHERE MaSach = @MaSach
	ELSE IF EXISTS (SELECT * FROM Sach_NhaNuoc WHERE MaSach = @MaSach)
		DELETE FROM Sach_NhaNuoc WHERE MaSach = @MaSach
	
	PRINT N'Đã xóa sách Mức 2'
GO
PRINT N'--- TEST CÂU 5 - MỨC 2 ---'
-- (Có thể tạo data mồi S004_M2 để test nếu Mức 1 đã xóa mất)
EXEC XoaSachMuc2 N'S004'
EXEC XoaSachMuc2 N'S005'
GO