# PowerShell script to fetch todos from Android app via ADB
# This script queries the SQLite database directly using ADB commands

# Configuration
$packageName = "com.notetaking.app.note_taking_app"
$databasePath = "/data/data/$packageName/databases/todo_app.db"

try {
    # Check if ADB is available
    $adbCheck = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adbCheck) {
        Write-Host "Error: ADB not found in PATH" -ForegroundColor Red
        exit 1
    }

    # Check if device/emulator is connected
    Write-Host "Checking for connected devices..."
    $devices = adb devices
    if ($devices -match "emulator-\d+\s+device" -or $devices -match "\w+\s+device") {
        Write-Host "Device/Emulator detected" -ForegroundColor Green
        
        # Try to check if database file exists
        Write-Host "Checking if database file exists..."
        $fileCheck = adb shell "run-as $packageName ls -la databases/" 2>&1
        Write-Host "Database directory contents: $fileCheck"
        
        # Try to check database schema first
        Write-Host "Checking database tables..."
        $schemaResult = adb shell "run-as $packageName sqlite3 databases/todo_app.db '.tables'" 2>&1
        if ($schemaResult -match "inaccessible|not found|No such file") {
            Write-Host "Schema check failed: $schemaResult"
        } else {
            Write-Host "Tables found: $schemaResult"
        }
        
        # Try direct SQL query via run-as with relative path
        Write-Host "Attempting to fetch todos..."
        $result = adb shell "run-as $packageName sqlite3 databases/todo_app.db 'SELECT COUNT(*) FROM todos WHERE is_deleted = 0;'" 2>&1
        
        if ($result -match "inaccessible|not found|No such file") {
            Write-Host "Direct query failed: $result"
            
            # Try with full path
            Write-Host "Trying with full database path..."
            $fullPathResult = adb shell "run-as $packageName sqlite3 $databasePath 'SELECT COUNT(*) FROM todos WHERE is_deleted = 0;'" 2>&1
            if ($fullPathResult -match "inaccessible|not found|No such file") {
                Write-Host "Full path query also failed: $fullPathResult"
                $todoCount = 0
            } else {
                $todoCount = $fullPathResult.Trim()
                Write-Host "Full path query successful: $todoCount todos found"
            }
        } else {
            $todoCount = $result.Trim()
            Write-Host "Direct query successful: $todoCount todos found"
        }
        
        # If we successfully got a count, try to fetch actual todo data
        if ($todoCount -match "^\d+$" -and [int]$todoCount -gt 0) {
            Write-Host "\nFetching todo details..."
            $todoDetails = adb shell "run-as $packageName sqlite3 databases/todo_app.db 'SELECT id, title, description, status, priority, due_date, created_at FROM todos WHERE is_deleted = 0 ORDER BY created_at DESC LIMIT 10;'" 2>&1
            
            if ($todoDetails -match "inaccessible|not found|No such file") {
                Write-Host "Failed to fetch todo details: $todoDetails"
            } else {
                Write-Host "\n=== TODO LIST ==="
                Write-Host $todoDetails
                Write-Host "================="
            }
        }
        
        Write-Host "\nTotal todos found: $todoCount" -ForegroundColor Cyan
        
    } else {
        Write-Host "No device or emulator connected" -ForegroundColor Red
        Write-Host "Available devices:"
        Write-Host $devices
        exit 1
    }
    
} catch {
    Write-Host "Error occurred: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "\nScript completed successfully" -ForegroundColor Green