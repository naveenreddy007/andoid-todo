# Comprehensive Flutter Todo App Functionality Test Script
# This script tests all major CRUD operations and navigation flows

Write-Host "=== Flutter Todo App Functionality Test ===" -ForegroundColor Green
Write-Host "Testing all major features and navigation flows..." -ForegroundColor Yellow

# Function to create ADB command file
function Create-ADBCommand {
    param(
        [string]$Action,
        [hashtable]$Data = @{}
    )
    
    $command = @{
        action = $Action
        data = $Data
        timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    
    $jsonCommand = $command | ConvertTo-Json -Depth 3
    $tempFile = "adb_command_temp.json"
    $jsonCommand | Out-File -FilePath $tempFile -Encoding UTF8
    
    # Push to device
    adb push $tempFile /data/data/com.notetaking.app.note_taking_app/files/adb_command.json
    Remove-Item $tempFile
    
    Write-Host "Sent command: $Action" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
}

# Test 1: Create a new todo
Write-Host "\n1. Testing Todo Creation..." -ForegroundColor Blue
Create-ADBCommand -Action "create_todo" -Data @{
    title = "Test Todo from Script"
    description = "This todo was created via test script to verify functionality"
    priority = "high"
    category = "work"
    dueDate = (Get-Date).AddDays(1).ToString("yyyy-MM-dd")
}

# Test 2: Create a new tag
Write-Host "\n2. Testing Tag Creation..." -ForegroundColor Blue
Create-ADBCommand -Action "create_tag" -Data @{
    name = "TestTag"
    color = "#FF5722"
}

# Test 3: List all todos
Write-Host "\n3. Testing Todo Listing..." -ForegroundColor Blue
Create-ADBCommand -Action "list_todos"

# Test 4: List all tags
Write-Host "\n4. Testing Tag Listing..." -ForegroundColor Blue
Create-ADBCommand -Action "list_tags"

# Test 5: Update a todo (we'll use a known ID from the logs)
Write-Host "\n5. Testing Todo Update..." -ForegroundColor Blue
Create-ADBCommand -Action "update_todo" -Data @{
    id = "a8cc6aad-9bf9-43b9-9731-a4898572b219"  # Using ID from logs
    title = "Updated Test Todo"
    description = "This todo was updated via test script"
    status = "completed"
}

# Test 6: Test search functionality
Write-Host "\n6. Testing Search Functionality..." -ForegroundColor Blue
Create-ADBCommand -Action "search_todos" -Data @{
    query = "test"
}

# Test 7: Test navigation (simulate navigation to different screens)
Write-Host "\n7. Testing Navigation Flow..." -ForegroundColor Blue
Create-ADBCommand -Action "navigate" -Data @{
    screen = "tags"
}

Start-Sleep -Seconds 2

Create-ADBCommand -Action "navigate" -Data @{
    screen = "categories"
}

Start-Sleep -Seconds 2

Create-ADBCommand -Action "navigate" -Data @{
    screen = "search"
}

Start-Sleep -Seconds 2

Create-ADBCommand -Action "navigate" -Data @{
    screen = "home"
}

# Test 8: Verify database integrity
Write-Host "\n8. Testing Database Integrity..." -ForegroundColor Blue
Create-ADBCommand -Action "dump_database"

Write-Host "\n=== Test Completed ===" -ForegroundColor Green
Write-Host "Check the Flutter app logs for results and verify:" -ForegroundColor Yellow
Write-Host "1. New todo appears in the list" -ForegroundColor White
Write-Host "2. New tag appears in tags screen" -ForegroundColor White
Write-Host "3. Todo update is reflected" -ForegroundColor White
Write-Host "4. Search returns relevant results" -ForegroundColor White
Write-Host "5. Navigation between screens works smoothly" -ForegroundColor White
Write-Host "6. Database operations complete without errors" -ForegroundColor White

Write-Host "\nTo monitor results, run: flutter logs" -ForegroundColor