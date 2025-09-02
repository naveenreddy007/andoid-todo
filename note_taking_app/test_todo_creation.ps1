#!/usr/bin/env pwsh
# Test script to create a todo and verify it appears in the database

param(
    [Parameter(Mandatory=$false)]
    [string]$Title = "Test Todo $(Get-Date -Format 'HH:mm:ss')",
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "Test description for debugging"
)

# Check for connected devices
Write-Host "Checking for connected devices..."
$devices = adb devices
if ($devices -notmatch "device") {
    Write-Host "No Android device/emulator connected"
    Write-Host "Please ensure an Android device or emulator is running and connected"
    exit 1
}
Write-Host "Device/Emulator detected"
Write-Host ""

# Get package name
$packageName = "com.notetaking.app.note_taking_app"
Write-Host "Package: $packageName"

# Generate unique ID
$todoId = [System.Guid]::NewGuid().ToString()
$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

Write-Host "Creating test todo..."
Write-Host "ID: $todoId"
Write-Host "Title: $Title"
Write-Host "Description: $Description"
Write-Host ""

# Create todo via ADB JSON command
$todoData = @{
    action = "create_todo"
    data = @{
        title = $Title
        description = $Description
        priority = "medium"
        status = "pending"
    }
} | ConvertTo-Json -Depth 3

# Send command via ADB
Write-Host "Sending create command..."
$result = adb shell "echo '$todoData' | run-as $packageName tee /data/data/$packageName/files/debug_command.json > /dev/null && run-as $packageName cat /data/data/$packageName/files/debug_response.json 2>/dev/null || echo 'No response file'"

Write-Host "Response: $result"
Write-Host ""

# Wait a moment for processing
Start-Sleep -Seconds 2

# Check database directly
Write-Host "Checking database for todos..."
$dbPath = "/data/data/$packageName/databases/todo_database.db"

try {
    $todoCount = adb shell "run-as $packageName sqlite3 $dbPath 'SELECT COUNT(*) FROM todos WHERE is_deleted = 0;'"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "📊 Total todos in database: $todoCount"
    } else {
        Write-Host "❌ Could not access database directly"
    }
} catch {
    Write-Host "❌ Error accessing database: $($_.Exception.Message)"
}

# Try to get recent todos
try {
    $recentTodos = adb shell "run-as $packageName sqlite3 $dbPath 'SELECT id, title, created_at FROM todos WHERE is_deleted = 0 ORDER BY created_at DESC LIMIT 5;'"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "📝 Recent todos:"
        Write-Host $recentTodos
    } else {
        Write-Host "❌ Could not fetch recent todos"
    }
} catch {
    Write-Host "❌ Error fetching todos: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "=== Test Complete ==="
Write-Host "If the todo count is 0, there's an issue with todo creation."
Write-Host "If the todo appears in database but not in UI, there's a stream/provider issue."