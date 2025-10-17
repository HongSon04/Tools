$exclusionPath = "C:\Program Files\RevoltG"

try {
    $currentExclusions = (Get-MpPreference).ExclusionPath

    if ($currentExclusions -contains $exclusionPath) {
        Write-Host "[INFO] Thư mục '$exclusionPath' đã tồn tại trong danh sách loại trừ." -ForegroundColor Yellow
    }
    else {
        Add-MpPreference -ExclusionPath $exclusionPath
        Write-Host "[SUCCESS] Đã thêm thành công thư mục '$exclusionPath' vào danh sách loại trừ!" -ForegroundColor Green
    }
}
catch {
    Write-Host "[ERROR] Đã có lỗi xảy ra. Không thể thêm loại trừ." -ForegroundColor Red
    Write-Host "Chi tiết lỗi: $_"
}

Write-Host "Cửa sổ sẽ tự động đóng sau 5 giây..."
Start-Sleep -Seconds 5