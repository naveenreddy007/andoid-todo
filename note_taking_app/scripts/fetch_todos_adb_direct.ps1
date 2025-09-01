#!/usr/bin/env pwsh
# ADB Todo Fetcher - Direct Database Query
# Fetches todos directly from SQLite database via ADB

param(
    [string]$Status = "",  # Filter by status: pending, completed, in_progress
    [switch]$Help
)

if ($Help) {
    Write-Host "ADB Todo Fetcher - Direct Database Query" -ForegroundColor Green
    Write-Host "Usage: .\fetch_todos_adb_direct.ps1 [-Status <status>] [-Help]"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -Status    Filter todos by status (pending, completed, in_progress)"
    Write-Host "  -Help      Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\fetch_todos_adb_direct.ps1                    # Get all todos"
    Write-Host "  .\fetch_todos_adb_direct.ps1 -Status pending   # Get pending todos only"
    Write-Host "  .\fetch_todos_adb_direct.ps1 -Status completed # Get completed todos only"
    exit 0
}

# Check if ADB is available
if (-not (Get-Command "adb" -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] ADB not found. Please ensure Android SDK is installed and ADB is in PATH." -ForegroundColor Red
    exit 1
}

# Check for connected devices
$devices = adb devices | Select-String -Pattern "\t(device|emulator)"
if ($devices.Count -eq 0) {
    Write-Host "[ERROR] No Android devices/emulators connected." -ForegroundColor Red
    Write-Host "Please start an emulator or connect a device." -ForegroundColor Yellow
    exit 1
}

$deviceId = ($devices[0] -split "\t")[0]
Write-Host "[INFO] Device detected: $deviceId" -ForegroundColor Green

# App package and database info
$packageName = "com.notetaking.app.note_taking_app"
$dbPath = "/data/data/$packageName/databases/todo_app.db"

Write-Host "[INFO] Fetching todos from SQLite database via ADB..." -ForegroundColor Cyan

# Build SQL query based on status filter
$sqlQuery = "SELECT id, title, description, status, priority, created_at, updated_at FROM todos"
if ($Status -ne "") {
    $sqlQuery += " WHERE status = '$Status'"
    Write-Host "[FILTER] Fetching todos with status: $Status" -ForegroundColor Yellow
} else {
    Write-Host "[ALL] Fetching all todos" -ForegroundColor Yellow
}
$sqlQuery += " ORDER BY created_at DESC;"

try {
    # First check what tables exist in the database
    Write-Host "[INFO] Checking database schema..." -ForegroundColor Cyan
    $schemaQuery = ".tables"
    $schemaResult = adb shell "run-as $packageName echo '$schemaQuery' | sqlite3 $dbPath"
    
    if ($LASTEXITCODE -eq 0 -and $schemaResult) {
        Write-Host "[INFO] Available tables: $schemaResult" -ForegroundColor Cyan
    } else {
        Write-Host "[WARNING] Could not retrieve database schema" -ForegroundColor Yellow
    }
    
    # Execute the main SQL query
    Write-Host "[INFO] Executing SQL query via ADB shell..." -ForegroundColor Cyan
    $result = adb shell "run-as $packageName echo '$sqlQuery' | sqlite3 $dbPath"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to execute SQL query. Exit code: $LASTEXITCODE" -ForegroundColor Red
        
        # Try alternative approach with different sqlite3 syntax
        Write-Host "[INFO] Trying alternative query method..." -ForegroundColor Cyan
        $result = adb shell "run-as $packageName sqlite3 $dbPath '$sqlQuery'"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Alternative query method also failed. Exit code: $LASTEXITCODE" -ForegroundColor Red
            exit 1
        }
    }
    
    # Parse results
    $todos = @()
    $lines = $result -split "`n" | Where-Object { $_.Trim() -ne "" }
    
    foreach ($line in $lines) {
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
            $todos += $todo
        }
    }
    
    # Display results
    if ($todos.Count -eq 0) {
        Write-Host "[INFO] No todos found in database" -ForegroundColor Yellow
    } else {
        Write-Host "[SUCCESS] Found $($todos.Count) todo(s)" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== TODOS ===" -ForegroundColor Cyan
        
        foreach ($todo in $todos) {
            $statusColor = switch ($todo.Status) {
                "completed" { "Green" }
                "pending" { "Yellow" }
                "in_progress" { "Blue" }
                default { "White" }
            }
            
            $priorityColor = switch ($todo.Priority) {
                "urgent" { "Red" }
                "high" { "Magenta" }
                "medium" { "Yellow" }
                "low" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$($todo.Id)] " -NoNewline -ForegroundColor Gray
            Write-Host "$($todo.Title)" -NoNewline -ForegroundColor White
            Write-Host " (" -NoNewline
            Write-Host "$($todo.Status)" -NoNewline -ForegroundColor $statusColor
            Write-Host ") - " -NoNewline
            Write-Host "$($todo.Priority)" -ForegroundColor $priorityColor
            
            if ($todo.Description -and $todo.Description.Trim() -ne "") {
                Write-Host "    Description: $($todo.Description)" -ForegroundColor Gray
            }
            
            Write-Host "    Created: $($todo.CreatedAt)" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    Write-Host "[SUCCESS] Successfully fetched $($todos.Count) todo(s) from database" -ForegroundColor Green
    
} catch {
    Write-Host "[ERROR] Failed to fetch todos: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[DEBUG] Additional commands:" -ForegroundColor Magenta
Write-Host "  Create todo: .\scripts\create_todo_adb.ps1 -Title 'New Todo' -Priority high" -ForegroundColor Gray
Write-Host "  View database: adb shell \"run-as $packageName sqlite3 $dbPath \"SELECT * FROM todos;\"\""
Write-Host "  App logs: adb logcat -s flutter" -ForegroundColor Gray