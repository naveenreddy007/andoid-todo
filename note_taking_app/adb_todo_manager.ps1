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
    
    adb push $tempFile "/data/data/com.notetaking.app.note_taking_app/files/adb_command.json"
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Check for response file
    $responseExists = adb shell "run-as com.notetaking.app.note_taking_app test -f files/adb_response.json && echo 'exists' || echo 'not found'"
    
    if ($responseExists.Trim() -eq "exists") {
        $response = adb shell "run-as com.notetaking.app.note_taking_app cat files/adb_response.json"
        adb shell "run-as com.notetaking.app.note_taking_app rm files/adb_response.json"
        
        $responseObj = $response | ConvertFrom-Json
        if ($responseObj.success) {
            Write-Host "✅ Todo created successfully: $($responseObj.data.title)"
        } else {
            Write-Host "❌ Error creating todo: $($responseObj.error)"
        }
    } else {
        Write-Host "No response received from app"
    }
}

function Get-AdbTodos {
    # Create command file
    $commandData = @{
        action = "get_todos"
        data = @{}
    }
    
    $commandJson = $commandData | ConvertTo-Json -Depth 3
    $tempFile = [System.IO.Path]::GetTempFileName()
    $commandJson | Out-File -FilePath $tempFile -Encoding UTF8
    
    Write-Host "Fetching todos..."
    
    # Push command file to device
    adb push $tempFile /data/data/com.notetaking.app.note_taking_app/files/adb_command.json
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Check for response file
    $responseExists = adb shell "run-as com.notetaking.app.note_taking_app test -f files/adb_response.json && echo 'exists' || echo 'not found'"
    
    if ($responseExists.Trim() -eq "exists") {
        $response = adb shell "run-as com.notetaking.app.note_taking_app cat files/adb_response.json"
        adb shell "run-as com.notetaking.app.note_taking_app rm files/adb_response.json"
        
        $responseObj = $response | ConvertFrom-Json
        if ($responseObj.success) {
            Write-Host "Found $($responseObj.data.Count) todos:" -ForegroundColor Green
            foreach ($todo in $responseObj.data) {
                Write-Host "  [$($todo.status)] $($todo.title) - $($todo.priority)" -ForegroundColor Cyan
                if ($todo.description) {
                    Write-Host "    Description: $($todo.description)" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host "Error fetching todos: $($responseObj.error)" -ForegroundColor Red
        }
    } else {
        Write-Host "No response received from app" -ForegroundColor Yellow
    }
}

function Get-AdbTodoCount {
    $commandData = @{
        action = "get_todo_count"
        data = @{}
    }
    
    $commandJson = $commandData | ConvertTo-Json -Depth 3
    
    Write-Host "Getting todo count..."
    
    # Write command to device
    $tempFile = [System.IO.Path]::GetTempFileName()
    $commandJson | Out-File -FilePath $tempFile -Encoding UTF8
    
    adb push $tempFile "/data/data/com.notetaking.app.note_taking_app/files/adb_command.json"
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Check for response file
    $responseExists = adb shell "run-as com.notetaking.app.note_taking_app test -f files/adb_response.json && echo 'exists' || echo 'not found'"
    
    if ($responseExists.Trim() -eq "exists") {
        $response = adb shell "run-as com.notetaking.app.note_taking_app cat files/adb_response.json"
        adb shell "run-as com.notetaking.app.note_taking_app rm files/adb_response.json"
        
        $responseObj = $response | ConvertFrom-Json
        if ($responseObj.success) {
            Write-Host "Total todos: $($responseObj.data.count)" -ForegroundColor Green
        } else {
            Write-Host "Error getting todo count: $($responseObj.error)" -ForegroundColor Red
        }
    } else {
        Write-Host "No response received from app" -ForegroundColor Yellow
    }
}

function Remove-AdbTodo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Id
    )
    
    $commandData = @{
        action = "delete_todo"
        data = @{
            id = $Id
        }
    }
    
    $commandJson = $commandData | ConvertTo-Json -Depth 3
    
    Write-Host "Deleting todo with ID: $Id"
    
    # Write command to device
    $tempFile = [System.IO.Path]::GetTempFileName()
    $commandJson | Out-File -FilePath $tempFile -Encoding UTF8
    
    adb push $tempFile "/data/data/com.notetaking.app.note_taking_app/files/adb_command.json"
    Remove-Item $tempFile
    
    # Wait for response
    Start-Sleep -Seconds 3
    
    # Check for response file
    $responseExists = adb shell "run-as com.notetaking.app.note_taking_app test -f files/adb_response.json && echo 'exists' || echo 'not found'"
    
    if ($responseExists.Trim() -eq "exists") {
        $response = adb shell "run-as com.notetaking.app.note_taking_app cat files/adb_response.json"
        adb shell "run-as com.notetaking.app.note_taking_app rm files/adb_response.json"
        
        $responseObj = $response | ConvertFrom-Json
        if ($responseObj.success) {
            Write-Host "Todo deleted successfully!" -ForegroundColor Green
        } else {
            Write-Host "Error deleting todo: $($responseObj.error)" -ForegroundColor Red
        }
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