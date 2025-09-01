#!/usr/bin/env pwsh
# PowerShell script to fetch todos from Flutter app via debug logs
# This script triggers a hot reload to get fresh database dump from Flutter logs

param(
    [string]$Status = "",
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: fetch_todos_flutter_logs.ps1 [-Status <status>] [-Help]" -ForegroundColor Green
    Write-Host "" 
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Status    Filter todos by status (pending, completed, in_progress)" -ForegroundColor Gray
    Write-Host "  -Help      Show this help message" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\scripts\fetch_todos_flutter_logs.ps1" -ForegroundColor Gray
    Write-Host "  .\scripts\fetch_todos_flutter_logs.ps1 -Status pending" -ForegroundColor Gray
    exit 0
}

# Check if ADB is available
if (-not (Get-Command "adb" -ErrorAction SilentlyContinue)) {
    Write-Error "ADB is not available in PATH. Please install Android SDK and add ADB to PATH."
    exit 1
}

# Check for connected Android devices
$devices = adb devices | Select-String "device$"
if ($devices.Count -eq 0) {
    Write-Error "No Android device connected. Please connect a device or start an emulator."
    exit 1
}

$deviceId = ($devices[0] -split "\t")[0]
Write-Host "[INFO] Device detected: $deviceId" -ForegroundColor Green

# Function to extract todos from Flutter logs
function Extract-TodosFromLogs {
    param([string[]]$LogLines)
    
    $todos = @()
    $todoCount = 0
    
    foreach ($line in $LogLines) {
        # Look for the debug helper format: "I/flutter ( 9635):   - Title (status) - priority"
        if ($line -match "I/flutter.*?:\s+-\s+(.+?)\s+\((.+?)\)\s+-\s+(.+?)\s*$") {
            $title = $matches[1].Trim()
            $status = $matches[2].Trim()
            $priority = $matches[3].Trim()
            
            $todoCount++
            $todo = @{
                Id = $todoCount
                Title = $title
                Description = ""
                Status = $status
                Priority = $priority
                CreatedAt = "N/A"
                UpdatedAt = "N/A"
            }
            
            # Filter by status if specified
            if ($Status -eq "" -or $todo.Status -eq $Status) {
                $todos += $todo
            }
        }
        
        # Also look for the database dump format if it exists
        if ($line -match "=== TODOS DUMP START ===") {
            $inTodosDump = $true
            continue
        }
        
        if ($line -match "=== TODOS DUMP END ===") {
            $inTodosDump = $false
            break
        }
        
        if ($inTodosDump -and $line -match "Total todos: (\d+)") {
            $totalCount = $matches[1]
            Write-Host "[INFO] Found $totalCount todos in database" -ForegroundColor Cyan
            continue
        }
        
        if ($inTodosDump -and $line -match "^\d+\|") {
            # Parse todo line: id|title|description|status|priority|createdAt|updatedAt
            $parts = $line -split "\|"
            if ($parts.Length -ge 7) {
                $todo = @{
                    Id = $parts[0]
                    Title = $parts[1]
                    Description = $parts[2]
                    Status = $parts[3]
                    Priority = $parts[4]
                    CreatedAt = $parts[5]
                    UpdatedAt = $parts[6]
                }
                
                # Filter by status if specified
                if ($Status -eq "" -or $todo.Status -eq $Status) {
                    $todos += $todo
                }
            }
        }
    }
    
    return $todos
}

try {
    Write-Host "[INFO] Fetching todos from Flutter app via debug logs..." -ForegroundColor Cyan
    
    if ($Status -ne "") {
        Write-Host "[FILTER] Status: $Status" -ForegroundColor Yellow
    } else {
        Write-Host "[ALL] Fetching all todos" -ForegroundColor Yellow
    }
    
    # Clear logcat buffer
    adb logcat -c
    
    # Trigger hot reload to get fresh database dump
    Write-Host "[INFO] Triggering hot reload to get fresh database dump..." -ForegroundColor Cyan
    adb shell input keyevent KEYCODE_R
    
    # Wait a moment for the reload to process
    Start-Sleep -Seconds 3
    
    # Capture recent logs
    Write-Host "[INFO] Capturing Flutter logs..." -ForegroundColor Cyan
    $logOutput = adb logcat -d | Where-Object { $_ -match "I/flutter" }
    $logLines = $logOutput
    
    # Debug: Show some log lines for troubleshooting
    Write-Host "[DEBUG] Sample log lines:" -ForegroundColor Magenta
    $logLines | Select-Object -Last 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to capture logs. Exit code: $LASTEXITCODE"
        exit 1
    }
    
    # Extract todos from logs
    $todos = Extract-TodosFromLogs -LogLines $logOutput
    
    if ($todos.Count -eq 0) {
        if ($Status -ne "") {
            Write-Host "[INFO] No todos found with status '$Status'" -ForegroundColor Yellow
        } else {
            Write-Host "[INFO] No todos found in database" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[SUCCESS] Found $($todos.Count) todo(s):" -ForegroundColor Green
        Write-Host "================================================================================" -ForegroundColor Gray
        
        foreach ($todo in $todos) {
            Write-Host "ID: $($todo.Id)" -ForegroundColor White
            Write-Host "Title: $($todo.Title)" -ForegroundColor Cyan
            Write-Host "Description: $($todo.Description)" -ForegroundColor Gray
            Write-Host "Status: $($todo.Status)" -ForegroundColor $(if ($todo.Status -eq "completed") { "Green" } elseif ($todo.Status -eq "pending") { "Yellow" } else { "Magenta" })
            Write-Host "Priority: $($todo.Priority)" -ForegroundColor $(if ($todo.Priority -eq "high") { "Red" } elseif ($todo.Priority -eq "medium") { "Yellow" } else { "Green" })
            Write-Host "Created: $($todo.CreatedAt)" -ForegroundColor Gray
            Write-Host "Updated: $($todo.UpdatedAt)" -ForegroundColor Gray
            Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "[SUCCESS] Successfully fetched $($todos.Count) todo(s) from Flutter logs" -ForegroundColor Green
    
    # Show additional debug info
    Write-Host ""
    Write-Host "[DEBUG] Additional commands:" -ForegroundColor DarkCyan
    Write-Host "  View all logs: adb logcat -s flutter" -ForegroundColor Gray
    Write-Host "  Clear logs: adb logcat -c" -ForegroundColor Gray
    Write-Host "  Hot reload: adb shell input keyevent KEYCODE_R" -ForegroundColor Gray
    
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}