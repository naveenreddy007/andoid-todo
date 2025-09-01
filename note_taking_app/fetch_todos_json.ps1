#!/usr/bin/env pwsh
# PowerShell script to fetch todos from Flutter app via ADB using JSON communication

Write-Host "=== ADB Todo Fetcher (JSON Communication) ==="
Write-Host "This script communicates with the Flutter app via JSON files"
Write-Host ""

# Configuration
$packageName = "com.notetaking.app.note_taking_app"
$appFilesPath = "/data/data/$packageName/files"
$commandFile = "$appFilesPath/adb_command.json"
$responseFile = "$appFilesPath/adb_response.json"

function Wait-ForResponse {
    param(
        [int]$TimeoutSeconds = 10
    )
    
    $elapsed = 0
    $checkInterval = 0.5
    
    while ($elapsed -lt $TimeoutSeconds) {
        $result = adb shell "run-as $packageName test -f $responseFile && echo 'exists' || echo 'not_found'" 2>&1
        if ($result -match "exists") {
            return $true
        }
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        Write-Host "." -NoNewline
    }
    Write-Host ""
    return $false
}

function Send-AdbCommand {
    param(
        [string]$Action,
        [hashtable]$Data = @{}
    )
    
    # Create command JSON
    $command = @{
        action = $Action
        data = $Data
        timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    }
    
    $commandJson = $command | ConvertTo-Json -Compress
    Write-Host "Sending command: $Action"
    
    # Clean up any existing response file
    adb shell "run-as $packageName rm -f $responseFile" 2>&1 | Out-Null
    
    # Write command file using base64 encoding to avoid shell escaping issues
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($commandJson)
    $base64 = [System.Convert]::ToBase64String($bytes)
    adb shell "run-as $packageName sh -c 'echo $base64 | base64 -d > $commandFile'" 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to write command file"
        return $null
    }
    
    # Wait for response
    Write-Host "Waiting for response" -NoNewline
    if (Wait-ForResponse -TimeoutSeconds 15) {
        Write-Host "Response received"
        
        # Read response
        $responseJson = adb shell "run-as $packageName cat $responseFile" 2>&1
        if ($LASTEXITCODE -eq 0) {
            try {
                $response = $responseJson | ConvertFrom-Json
                
                # Clean up response file
                adb shell "run-as $packageName rm -f $responseFile" 2>&1 | Out-Null
                
                return $response
            } catch {
                Write-Host "Failed to parse response JSON: $responseJson"
                return $null
            }
        } else {
            Write-Host "Failed to read response file: $responseJson"
            return $null
        }
    } else {
        Write-Host "Timeout waiting for response"
        return $null
    }
}

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

# Test 1: Get todo count
Write-Host "=== Getting Todo Count ==="
$countResponse = Send-AdbCommand -Action "get_todo_count"
if ($countResponse -and $countResponse.success) {
    $todoCount = $countResponse.data.count
    Write-Host "Total todos in database: $todoCount"
} else {
    Write-Host "Failed to get todo count"
    $todoCount = 0
}
Write-Host ""

# Test 2: Get all todos
if ($todoCount -gt 0) {
    Write-Host "=== Fetching All Todos ==="
    $todosResponse = Send-AdbCommand -Action "get_todos"
    
    if ($todosResponse -and $todosResponse.success) {
        $todos = $todosResponse.data
        Write-Host "Found $($todos.Count) todos:"
        Write-Host ""
        
        foreach ($todo in $todos) {
            $createdDate = [DateTimeOffset]::FromUnixTimeMilliseconds($todo.created_at).ToString("yyyy-MM-dd HH:mm:ss")
            $updatedDate = [DateTimeOffset]::FromUnixTimeMilliseconds($todo.updated_at).ToString("yyyy-MM-dd HH:mm:ss")
            
            Write-Host "ID: $($todo.id)"
            Write-Host "   Title: $($todo.title)"
            Write-Host "   Description: $($todo.description)"
            Write-Host "   Status: $($todo.status)"
            Write-Host "   Priority: $($todo.priority)"
            Write-Host "   Created: $createdDate"
            Write-Host "   Updated: $updatedDate"
            Write-Host ""
        }
    } else {
        Write-Host "Failed to fetch todos"
    }
} else {
    Write-Host "No todos to fetch"
}

Write-Host "=== Script completed successfully ==="