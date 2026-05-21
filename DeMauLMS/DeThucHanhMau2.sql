--Mã số sinh viên: 
--Họ tên sinh viên: 
--Số máy tính:		
--Chú ý: cuối giờ nộp file .sql này (MSSV_HoTenKhongDau_SoMay.sql) vào ổ Z:\

-- ======================================================================
-- CÂU 1: TẠO PHÂN MẢNH
-- ======================================================================
IF OBJECT_ID('TaoPhanManhNSX', 'P') IS NOT NULL DROP PROC TaoPhanManhNSX;
GO
CREATE PROC TaoPhanManhNSX
AS
	IF OBJECT_ID('NSX_TuNhan', 'U') IS NOT NULL DROP TABLE NSX_TuNhan;
	IF OBJECT_ID('NSX_NhaNuoc', 'U') IS NOT NULL DROP TABLE NSX_NhaNuoc;

	SELECT * INTO NSX_TuNhan FROM NhaSanXuat WHERE LoaiHinh = N'Tư nhân'
	SELECT * INTO NSX_NhaNuoc FROM NhaSanXuat WHERE LoaiHinh = N'Nhà nước'
GO
EXEC TaoPhanManhNSX
GO

IF OBJECT_ID('TaoPhanManhHH', 'P') IS NOT NULL DROP PROC TaoPhanManhHH;
GO
CREATE PROC TaoPhanManhHH
AS
	IF OBJECT_ID('HH_TuNhan', 'U') IS NOT NULL DROP TABLE HH_TuNhan;
	IF OBJECT_ID('HH_NhaNuoc', 'U') IS NOT NULL DROP TABLE HH_NhaNuoc;

	SELECT * INTO HH_TuNhan FROM HangHoa WHERE MaNSX IN (SELECT MaNSX FROM NSX_TuNhan)
	SELECT * INTO HH_NhaNuoc FROM HangHoa WHERE MaNSX IN (SELECT MaNSX FROM NSX_NhaNuoc)
GO
EXEC TaoPhanManhHH
GO


-- ======================================================================
-- CÂU 2: LẬP DANH SÁCH HÀNG HÓA THEO LOẠI HÌNH
-- Lưu ý: Câu này lọc theo Loại hình (chính là khóa phân mảnh), nên Mức 2 không cần UNION
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('DS_HH_Muc1', 'P') IS NOT NULL DROP PROC DS_HH_Muc1;
GO
CREATE PROC DS_HH_Muc1 @LoaiHinh NVARCHAR(50)
AS
	SELECT h.MaHH, h.TenHH, n.MaNSX, n.LoaiHinh
	FROM NhaSanXuat n JOIN HangHoa h ON n.MaNSX = h.MaNSX
	WHERE n.LoaiHinh = @LoaiHinh
GO
PRINT N'--- TEST CÂU 2 - MỨC 1 ---'
EXEC DS_HH_Muc1 N'Tư nhân'
GO

-- Mức 2:
IF OBJECT_ID('DS_HH_Muc2', 'P') IS NOT NULL DROP PROC DS_HH_Muc2;
GO
CREATE PROC DS_HH_Muc2 @LoaiHinh NVARCHAR(50)
AS
	-- Biết trước bảng nào chứa dữ liệu loại hình nào nên chỉ cần IF...ELSE
	IF @LoaiHinh = N'Tư nhân'
		SELECT h.MaHH, h.TenHH, n.MaNSX, n.LoaiHinh
		FROM NSX_TuNhan n JOIN HH_TuNhan h ON n.MaNSX = h.MaNSX
	ELSE IF @LoaiHinh = N'Nhà nước'
		SELECT h.MaHH, h.TenHH, n.MaNSX, n.LoaiHinh
		FROM NSX_NhaNuoc n JOIN HH_NhaNuoc h ON n.MaNSX = h.MaNSX
GO
PRINT N'--- TEST CÂU 2 - MỨC 2 ---'
EXEC DS_HH_Muc2 N'Nhà nước'
GO


-- ======================================================================
-- CÂU 3: THÊM NSX
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('ThemNSXMuc1', 'P') IS NOT NULL DROP PROC ThemNSXMuc1;
GO
CREATE PROC ThemNSXMuc1 @MaNSX NVARCHAR(20), @TenNSX NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF NOT EXISTS (SELECT * FROM NhaSanXuat WHERE MaNSX = @MaNSX)
	BEGIN
		INSERT INTO NhaSanXuat VALUES (@MaNSX, @TenNSX, @LoaiHinh)
		PRINT N'Thêm thành công Mức 1'
	END
GO
PRINT N'--- TEST CÂU 3 - MỨC 1 ---'
EXEC ThemNSXMuc1 N'HONDAVN', N'Công ty Honda Việt nam', N'Tư nhân'
EXEC ThemNSXMuc1 N'BETAMEX', N'Công ty xuất nhập khẩu BETA', N'Nhà nước'
GO

-- Mức 2:
IF OBJECT_ID('ThemNSXMuc2', 'P') IS NOT NULL DROP PROC ThemNSXMuc2;
GO
CREATE PROC ThemNSXMuc2 @MaNSX NVARCHAR(20), @TenNSX NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF NOT EXISTS (SELECT * FROM NSX_TuNhan WHERE MaNSX = @MaNSX) 
	   AND NOT EXISTS (SELECT * FROM NSX_NhaNuoc WHERE MaNSX = @MaNSX)
	BEGIN
		IF @LoaiHinh = N'Tư nhân'
			INSERT INTO NSX_TuNhan VALUES (@MaNSX, @TenNSX, @LoaiHinh)
		ELSE IF @LoaiHinh = N'Nhà nước'
			INSERT INTO NSX_NhaNuoc VALUES (@MaNSX, @TenNSX, @LoaiHinh)
		PRINT N'Thêm thành công Mức 2'
	END
GO
PRINT N'--- TEST CÂU 3 - MỨC 2 ---'
EXEC ThemNSXMuc2 N'HONDAVN_M2', N'Công ty Honda Việt nam', N'Tư nhân'
EXEC ThemNSXMuc2 N'BETAMEX_M2', N'Công ty xuất nhập khẩu BETA', N'Nhà nước'
GO


-- ======================================================================
-- CÂU 4: SỬA NSX (CÓ XỬ LÝ DỜI DỮ LIỆU)
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('SuaNSXMuc1', 'P') IS NOT NULL DROP PROC SuaNSXMuc1;
GO
CREATE PROC SuaNSXMuc1 @MaNSX NVARCHAR(20), @TenNSX NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF EXISTS (SELECT * FROM NhaSanXuat WHERE MaNSX = @MaNSX)
	BEGIN
		UPDATE NhaSanXuat SET TenNSX = @TenNSX, LoaiHinh = @LoaiHinh WHERE MaNSX = @MaNSX
		PRINT N'Sửa thành công Mức 1'
	END
GO
PRINT N'--- TEST CÂU 4 - MỨC 1 ---'
EXEC SuaNSXMuc1 N'CADIVI', N'Công ty cổ phần cáp điện Việt nam', N'Tư nhân'
EXEC SuaNSXMuc1 N'KINHDO', N'Công ty cổ phần Kinh đô', N'Tư nhân'
GO

-- Mức 2:
IF OBJECT_ID('SuaNSXMuc2', 'P') IS NOT NULL DROP PROC SuaNSXMuc2;
GO
CREATE PROC SuaNSXMuc2 @MaNSX NVARCHAR(20), @TenNSX NVARCHAR(50), @LoaiHinh NVARCHAR(50)
AS
	IF EXISTS (SELECT * FROM NSX_TuNhan WHERE MaNSX = @MaNSX)
	BEGIN
		UPDATE NSX_TuNhan SET TenNSX = @TenNSX, LoaiHinh = @LoaiHinh WHERE MaNSX = @MaNSX
		IF @LoaiHinh = N'Nhà nước'
		BEGIN
			-- Gốc sang trước, Ngọn sang sau. Ngọn xóa trước, Gốc xóa sau.
			INSERT INTO NSX_NhaNuoc SELECT * FROM NSX_TuNhan WHERE MaNSX = @MaNSX
			INSERT INTO HH_NhaNuoc SELECT * FROM HH_TuNhan WHERE MaNSX = @MaNSX
			DELETE FROM HH_TuNhan WHERE MaNSX = @MaNSX
			DELETE FROM NSX_TuNhan WHERE MaNSX = @MaNSX
			PRINT N'Đã dời NSX và Hàng hóa sang nhánh Nhà nước!'
		END
	END
	ELSE IF EXISTS (SELECT * FROM NSX_NhaNuoc WHERE MaNSX = @MaNSX)
	BEGIN
		UPDATE NSX_NhaNuoc SET TenNSX = @TenNSX, LoaiHinh = @LoaiHinh WHERE MaNSX = @MaNSX
		IF @LoaiHinh = N'Tư nhân'
		BEGIN
			INSERT INTO NSX_TuNhan SELECT * FROM NSX_NhaNuoc WHERE MaNSX = @MaNSX
			INSERT INTO HH_TuNhan SELECT * FROM HH_NhaNuoc WHERE MaNSX = @MaNSX
			DELETE FROM HH_NhaNuoc WHERE MaNSX = @MaNSX
			DELETE FROM NSX_NhaNuoc WHERE MaNSX = @MaNSX
			PRINT N'Đã dời NSX và Hàng hóa sang nhánh Tư nhân!'
		END
	END
GO
PRINT N'--- TEST CÂU 4 - MỨC 2 ---'
-- Ở đây theo đề bài không yêu cầu đổi loại hình, chỉ sửa tên, nên test sẽ chạy thành công mà không dời.
EXEC SuaNSXMuc2 N'CADIVI_M2', N'Công ty cổ phần cáp điện Việt nam', N'Tư nhân'
EXEC SuaNSXMuc2 N'KINHDO_M2', N'Công ty cổ phần Kinh đô', N'Tư nhân'
GO


-- ======================================================================
-- CÂU 5: XÓA HÀNG HÓA
-- ======================================================================
-- Mức 1:
IF OBJECT_ID('Xoa_HH_Muc1', 'P') IS NOT NULL DROP PROC Xoa_HH_Muc1;
GO
CREATE PROC Xoa_HH_Muc1 @MaHH NVARCHAR(20)
AS
	DELETE FROM HangHoa WHERE MaHH = @MaHH
	PRINT N'Đã xóa Hàng hóa Mức 1'
GO
PRINT N'--- TEST CÂU 5 - MỨC 1 ---'
EXEC Xoa_HH_Muc1 N'DH0131'
EXEC Xoa_HH_Muc1 N'SCHUA76'
GO

-- Mức 2:
IF OBJECT_ID('Xoa_HH_Muc2', 'P') IS NOT NULL DROP PROC Xoa_HH_Muc2;
GO
CREATE PROC Xoa_HH_Muc2 @MaHH NVARCHAR(20)
AS
	IF EXISTS (SELECT * FROM HH_TuNhan WHERE MaHH = @MaHH)
		DELETE FROM HH_TuNhan WHERE MaHH = @MaHH
	ELSE IF EXISTS (SELECT * FROM HH_NhaNuoc WHERE MaHH = @MaHH)
		DELETE FROM HH_NhaNuoc WHERE MaHH = @MaHH
	PRINT N'Đã xóa Hàng hóa Mức 2'
GO
PRINT N'--- TEST CÂU 5 - MỨC 2 ---'
EXEC Xoa_HH_Muc2 N'DH0131'
EXEC Xoa_HH_Muc2 N'SCHUA76'
GO