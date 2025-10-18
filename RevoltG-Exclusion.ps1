# --- Cấu hình Cố định ---
$exclusionPath = "C:\Program Files\RevoltG"
$fileNameToFind = "RevoltG.exe"
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
$valueName = "VerifiedAndReputablePolicyState"

# --- Hàm 1: Quản lý Windows Defender Exclusion ---
function Add-RevoltGExclusion {
    Write-Host "`n--- 1. Quản lý Windows Defender Exclusion ---" -ForegroundColor Yellow

    # Tìm đường dẫn động nếu cần
    $pathToAdd = $null
    if (Test-Path -Path $exclusionPath -PathType Container) {
        $pathToAdd = $exclusionPath
    }
    else {
        Write-Host "[INFO] Không tìm thấy thư mục mặc định. Đang tìm kiếm file '$fileNameToFind'..." -ForegroundColor Yellow
        $localDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -ne "" -and $_.Root -match "^[A-Z]:\\$" }
        
        foreach ($drive in $localDrives) {
            foreach ($folder in @("$($drive.Root)Program Files", "$($drive.Root)Program Files (x86)")) {
                if (Test-Path -Path $folder) {
                    $foundFile = Get-ChildItem -Path $folder -Filter $fileNameToFind -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($foundFile) {
                        $pathToAdd = $foundFile.Directory.FullName
                        break
                    }
                }
            }
            if ($pathToAdd) { break }
        }
    }

    if ($pathToAdd) {
        try {
            $currentExclusions = (Get-MpPreference).ExclusionPath

            if ($currentExclusions -contains $pathToAdd) {
                Write-Host "[INFO] Thư mục '$pathToAdd' đã tồn tại trong danh sách loại trừ." -ForegroundColor Yellow
            }
            else {
                Add-MpPreference -ExclusionPath $pathToAdd
                Write-Host "[SUCCESS] Đã thêm thành công thư mục '$pathToAdd' vào danh sách loại trừ!" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "[ERROR] Đã có lỗi xảy ra khi thêm loại trừ. (Cần quyền Admin)" -ForegroundColor Red
            Write-Host "Chi tiết lỗi: $_"
        }
    }
    else {
        Write-Host "[ERROR] Không tìm thấy thư mục cài đặt của '$fileNameToFind'." -ForegroundColor Red
    }
}

# --- Hàm 2: Quản lý Smart App Control (SAC) ---
function Set-SmartAppControl ($stateValue, $stateName) {
    Write-Host "`n--- 2. Cài đặt Smart App Control: $stateName ---" -ForegroundColor Yellow
    
    # CẢNH BÁO nếu chọn TẮT
    if ($stateValue -eq 0) {
        Write-Host "[CẢNH BÁO QUAN TRỌNG] Tắt Smart App Control là KHÔNG THỂ ĐẢO NGƯỢC. Bạn sẽ phải CÀI LẠI WINDOWS để bật lại." -ForegroundColor Red
        $confirm = Read-Host "Bạn có chắc chắn muốn TẮT vĩnh viễn không? (Y/N)"
        if ($confirm -ne 'Y' -and $confirm -ne 'y') {
            Write-Host "[INFO] Hủy tác vụ TẮT Smart App Control." -ForegroundColor Cyan
            return
        }
    }

    try {
        # Tạo key Registry nếu chưa có (thường nằm trong Policy)
        if (-not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }
        
        # Thiết lập giá trị Registry
        Set-ItemProperty -Path $registryPath -Name $valueName -Value $stateValue -Type DWORD -Force
        
        Write-Host "[SUCCESS] Đã thiết lập Smart App Control thành '$stateName' trong Registry." -ForegroundColor Green
        
        # Chạy CiTool để áp dụng thay đổi ngay lập tức
        Write-Host "[INFO] Đang chạy CiTool.exe -r để áp dụng thay đổi (Cần quyền Admin)..." -ForegroundColor Cyan
        Start-Process -FilePath "CiTool.exe" -ArgumentList "-r" -Wait -ErrorAction SilentlyContinue
        
        Write-Host "[INFO] Vui lòng KHỞI ĐỘNG LẠI máy tính để áp dụng cài đặt Smart App Control mới!" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[ERROR] Đã có lỗi xảy ra khi chỉnh sửa Smart App Control. (Cần quyền Admin)" -ForegroundColor Red
        Write-Host "Chi tiết lỗi: $_"
    }
}

# --- Hàm 3: Menu Chính ---
function Show-Menu {
    Clear-Host
    Write-Host "================================================" -ForegroundColor White
    Write-Host "       CÔNG CỤ THIẾT LẬP BẢO MẬT WINDOWS        " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor White
    Write-Host "1. Thêm RevoltG vào Loại trừ Windows Defender." -ForegroundColor Green
    Write-Host "------------------------------------------------" -ForegroundColor White
    Write-Host "2. Smart App Control: BẬT / ON (Giá trị: 2)" -ForegroundColor Yellow
    Write-Host "3. Smart App Control: ĐÁNH GIÁ / Evaluation (Giá trị: 1)" -ForegroundColor Yellow
    Write-Host "4. Smart App Control: TẮT / OFF (Giá trị: 0) - CẢNH BÁO!" -ForegroundColor Red
    Write-Host "------------------------------------------------" -ForegroundColor White
    Write-Host "5. TÁC VỤ AIO: Thêm Loại trừ RevoltG VÀ Tắt SAC." -ForegroundColor Magenta
    Write-Host "------------------------------------------------" -ForegroundColor White
    Write-Host "6. Thoát khỏi Script." -ForegroundColor DarkGray
    Write-Host "================================================" -ForegroundColor White

    $choice = Read-Host "Nhập lựa chọn của bạn (1-6)"
    return $choice
}

# --- Vòng lặp Chính ---
while ($true) {
    $selection = Show-Menu
    
    switch ($selection) {
        "1" { Add-RevoltGExclusion }
        "2" { Set-SmartAppControl 2 "BẬT/ON" }
        "3" { Set-SmartAppControl 1 "ĐÁNH GIÁ/Evaluation" }
        "4" { Set-SmartAppControl 0 "TẮT/OFF" }
        "5" { 
            Add-RevoltGExclusion 
            Set-SmartAppControl 0 "TẮT/OFF"
        }
        "6" { break }
        default { 
            Write-Host "[ERROR] Lựa chọn không hợp lệ. Vui lòng thử lại." -ForegroundColor Red
        }
    }

    Write-Host "`nĐã hoàn thành. Nhấn phím bất kỳ để trở lại Menu..." -ForegroundColor DarkYellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Write-Host "`nĐã đóng chương trình. Cửa sổ sẽ tự động đóng sau 5 giây..."
Start-Sleep -Seconds 5
