@echo off
echo ==========================================
echo Sync RTL (flatten structure: .sv + .svh)
echo ==========================================

set SRC=F:\Work\Projects\CapstoneProject2\00_rtl
set DST=F:\Work\Projects\CapstoneProject2\20_syn\quartus\top\00_rtl

:: Tạo thư mục đích nếu chưa có
if not exist "%DST%" mkdir "%DST%"

:: 1. Dọn dẹp: Xóa cả file .sv và .svh cũ
echo Cleaning old files...
del /Q "%DST%\*.sv"
del /Q "%DST%\*.svh"

:: 2. Copy toàn bộ: Lấy cả .sv và .svh từ mọi thư mục con
echo Copying files...
for /R "%SRC%" %%f in (*.sv *.svh) do (
    copy "%%f" "%DST%" >nul
)

echo.
echo Done. All .sv and .svh files flattened into:
echo %DST%