$defaultExclusionPath = "C:\Program Files\RevoltG"
$fileNameToFind = "RevoltG.exe"

try {
    $exclusionPath = $null
   
    if (Test-Path -Path $defaultExclusionPath -PathType Container) {
        $exclusionPath = $defaultExclusionPath
        Write-Host "[INFO] Đã tìm thấy thư mục mặc định: '$exclusionPath'" -ForegroundColor Cyan
    }
    else {
        Write-Host "[INFO] Không tìm thấy thư mục mặc định. Đang tìm kiếm file '$fileNameToFind' trên các ổ đĩa..." -ForegroundColor Yellow
        
        $localDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -ne "" -and $_.Root -match "^[A-Z]:\\$" }
        
        foreach ($drive in $localDrives) {
            Write-Host "   - Đang tìm kiếm trên ổ đĩa $($drive.Name):\"
            $searchFolders = @("$($drive.Root)Program Files", "$($drive.Root)Program Files (x86)")
            
            foreach ($folder in $searchFolders) {
                if (Test-Path -Path $folder) {
                    $foundFile = Get-ChildItem -Path $folder -Filter $fileNameToFind -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    
                    if ($foundFile) {
                        $exclusionPath = $foundFile.Directory.FullName
                        Write-Host "[SUCCESS] Đã tìm thấy đường dẫn thư mục: '$exclusionPath' trên ổ đĩa $($drive.Name)." -ForegroundColor Green
                        break 
                    }
                }
            }
            if ($exclusionPath) {
                break 
            }
        }
    }
    
    if ($exclusionPath) {
        $currentExclusions = (Get-MpPreference).ExclusionPath

        if ($currentExclusions -contains $exclusionPath) {
            Write-Host "`n[INFO] Thư mục '$exclusionPath' đã tồn tại trong danh sách loại trừ." -ForegroundColor Yellow
        }
        else {
            Add-MpPreference -ExclusionPath $exclusionPath
            Write-Host "`n[SUCCESS] Đã thêm thành công thư mục '$exclusionPath' vào danh sách loại trừ!" -ForegroundColor Green
        }
    }
    else {
        Write-Host "`n[ERROR] Không tìm thấy thư mục cài đặt của '$fileNameToFind' trên bất kỳ ổ đĩa nào." -ForegroundColor Red
        Write-Host "Vui lòng kiểm tra lại đường dẫn cài đặt thủ công."
    }

}
catch {
    Write-Host "`n[ERROR] Đã có lỗi xảy ra khi thực hiện thêm loại trừ." -ForegroundColor Red
    Write-Host "Chi tiết lỗi: $_"
    Write-Host "Lưu ý: Bạn cần chạy PowerShell với quyền Quản trị viên (Run as Administrator)."
}

Write-Host "`nCửa sổ sẽ tự động đóng sau 5 giây..."
Start-Sleep -Seconds 5
