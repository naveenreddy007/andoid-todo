# ADB Todo Manager Script
# This script provides easy commands to manage todos via ADB

function New-AdbTodo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("pending", "in_progress", "completed")]
        [string]$Status = "pending",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("low", "medium", "high")]
        [string]$Priority = "medium"
    )
    
    $command = @{
        action = "create_todo"
        data = @{
            title = $Title
            description = $Description
            status = $Status
            priority = $Priority
        }
    }
    
    $commandJson = $command | ConvertTo-Json -Depth 3
    
    Write-Host "Creating todo: $Title" -ForegroundColor Green
    
    # Write command to device
    $tempFile = [System.IO.Path]::GetTempFileName()
    $commandJson | Out-File -FilePath $tempFile -Encoding UTF8
    
    adb push $tempFile "/sdcard/adb_command.json"
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Get response
    adb pull "/sdcard/adb_response.json" "$env:TEMP\adb_response.json" 2>$null
    
    if (Test-Path "$env:TEMP\adb_response.json") {
        $response = Get-Content "$env:TEMP\adb_response.json" | ConvertFrom-Json
        
        if ($response.success) {
            Write-Host "Todo created successfully!" -ForegroundColor Green
            Write-Host "ID: $($response.data.id)" -ForegroundColor Cyan
            Write-Host "Title: $($response.data.title)" -ForegroundColor Cyan
            Write-Host "Status: $($response.data.status)" -ForegroundColor Cyan
            Write-Host "Priority: $($response.data.priority)" -ForegroundColor Cyan
        } else {
            Write-Host "Error creating todo: $($response.error)" -ForegroundColor Red
        }
        
        Remove-Item "$env:TEMP\adb_response.json"
    } else {
        Write-Host "No response received from app" -ForegroundColor Yellow
    }
}

function Get-AdbTodos {
    $command = @{
        action = "get_todos"
        data = @{}
    }
    
    $commandJson = $command | ConvertTo-Json -Depth 3
    
    Write-Host "Fetching todos..." -ForegroundColor Green
    
    # Write command to device
    $tempFile = [System.IO.Path]::GetTempFileName()
    $commandJson | Out-File -FilePath $tempFile -Encoding UTF8
    
    adb push $tempFile "/sdcard/adb_command.json"
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Get response
    adb pull "/sdcard/adb_response.json" "$env:TEMP\adb_response.json" 2>$null
    
    if (Test-Path "$env:TEMP\adb_response.json") {
        $response = Get-Content "$env:TEMP\adb_response.json" | ConvertFrom-Json
        
        if ($response.success) {
            Write-Host "Found $($response.data.Count) todos:" -ForegroundColor Green
            Write-Host ""
            
            foreach ($todo in $response.data) {
                Write-Host "$($todo.title)" -ForegroundColor Cyan
                Write-Host "   ID: $($todo.id)" -ForegroundColor Gray
                Write-Host "   Description: $($todo.description)" -ForegroundColor Gray
                Write-Host "   Status: $($todo.status)" -ForegroundColor Yellow
                Write-Host "   Priority: $($todo.priority)" -ForegroundColor Magenta
                Write-Host "   Created: $([DateTimeOffset]::FromUnixTimeMilliseconds($todo.created_at).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "Error fetching todos: $($response.error)" -ForegroundColor Red
        }
        
        Remove-Item "$env:TEMP\adb_response.json"
    } else {
        Write-Host "No response received from app" -ForegroundColor Yellow
    }
}

function Get-AdbTodoCount {
    $command = @{
        action = "get_todo_count"
        data = @{}
    }
    
    $commandJson = $command | ConvertTo-Json -Depth 3
    
    Write-Host "Getting todo count..." -ForegroundColor Green
    
    # Write command to device
    $tempFile = [System.IO.Path]::GetTempFileName()
    $commandJson | Out-File -FilePath $tempFile -Encoding UTF8
    
    adb push $tempFile "/sdcard/adb_command.json"
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Get response
    adb pull "/sdcard/adb_response.json" "$env:TEMP\adb_response.json" 2>$null
    
    if (Test-Path "$env:TEMP\adb_response.json") {
        $response = Get-Content "$env:TEMP\adb_response.json" | ConvertFrom-Json
        
        if ($response.success) {
            Write-Host "Total todos: $($response.data.count)" -ForegroundColor Green
        } else {
            Write-Host "Error getting todo count: $($response.error)" -ForegroundColor Red
        }
        
        Remove-Item "$env:TEMP\adb_response.json"
    } else {
        Write-Host "No response received from app" -ForegroundColor Yellow
    }
}

function Remove-AdbTodo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TodoId
    )
    
    $command = @{
        action = "delete_todo"
        data = @{
            id = $TodoId
        }
    }
    
    $commandJson = $command | ConvertTo-Json -Depth 3
    
    Write-Host "Deleting todo: $TodoId" -ForegroundColor Green
    
    # Write command to device
    $tempFile = [System.IO.Path]::GetTempFileName()
    $commandJson | Out-File -FilePath $tempFile -Encoding UTF8
    
    adb push $tempFile "/sdcard/adb_command.json"
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Get response
    adb pull "/sdcard/adb_response.json" "$env:TEMP\adb_response.json" 2>$null
    
    if (Test-Path "$env:TEMP\adb_response.json") {
        $response = Get-Content "$env:TEMP\adb_response.json" | ConvertFrom-Json
        
        if ($response.success) {
            Write-Host "Todo deleted successfully!" -ForegroundColor Green
            Write-Host "Deleted ID: $($response.data.deleted_id)" -ForegroundColor Cyan
        } else {
            Write-Host "Error deleting todo: $($response.error)" -ForegroundColor Red
        }
        
        Remove-Item "$env:TEMP\adb_response.json"
    } else {
        Write-Host "No response received from app" -ForegroundColor Yellow
    }
}

# Display usage information
function Show-AdbTodoHelp {
    Write-Host "ADB Todo Manager - Available Commands:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "New-AdbTodo -Title 'Task name' [-Description 'Details'] [-Status 'pending|in_progress|completed'] [-Priority 'low|medium|high']" -ForegroundColor Cyan
    Write-Host "   Creates a new todo item"
    Write-Host ""
    Write-Host "Get-AdbTodos" -ForegroundColor Cyan
    Write-Host "   Lists all todo items"
    Write-Host ""
    Write-Host "Get-AdbTodoCount" -ForegroundColor Cyan
    Write-Host "   Shows total number of todos"
    Write-Host ""
    Write-Host "Remove-AdbTodo -TodoId 'todo-id'" -ForegroundColor Cyan
    Write-Host "   Deletes a specific todo item"
    Write-Host ""
    Write-Host "Show-AdbTodoHelp" -ForegroundColor Cyan
    Write-Host "   Shows this help message"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "New-AdbTodo -Title 'Buy groceries' -Description 'Milk, bread, eggs' -Priority 'high'" -ForegroundColor Green
    Write-Host "New-AdbTodo -Title 'Call dentist' -Status 'pending'" -ForegroundColor Green
    Write-Host "Get-AdbTodos" -ForegroundColor Green
    Write-Host "Get-AdbTodoCount" -ForegroundColor Green
}

# Show help on script load
Show-AdbTodoHelp