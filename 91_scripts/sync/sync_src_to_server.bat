@echo off
echo ==========================================
echo Sync RTL (flatten structure: .sv + .svh)
echo ==========================================

:: ĐƯỜNG DẪN SOURCE VÀ DESTINATION (Giữ nguyên như cũ)
set SRC=F:\Work\Projects\CapstoneProject2\00_rtl
set DST=F:\Work\Projects\CapstoneProject2\10_sim\xcelium_server\00_src

:: Tạo thư mục đích nếu chưa có
if not exist "%DST%" mkdir "%DST%"

:: 1. Dọn dẹp: Xóa file cũ (.sv và .svh) để tránh trùng lặp hoặc file rác
echo Cleaning old files...
del /Q "%DST%\*.sv"
del /Q "%DST%\*.svh"

:: 2. Copy toàn bộ: Duyệt đệ quy (Recursive) lấy cả .sv và .svh
echo Copying files...
:: Cú pháp (*.sv *.svh) cho phép chọn nhiều đuôi file cùng lúc
for /R "%SRC%" %%f in (*.sv *.svh) do (
    copy "%%f" "%DST%" >nul
)

echo.
echo ==========================================
echo Done. All .sv and .svh files flattened into:
echo %DST%
echo ==========================================