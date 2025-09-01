# ADB Todo Helper Script
# This script provides functions to create and fetch todos via ADB commands

# Function to generate a UUID-like string
function New-UUID {
    return [System.Guid]::NewGuid().ToString()
}

# Function to get current timestamp in milliseconds
function Get-CurrentTimestamp {
    return [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
}

# Function to insert a todo via ADB
function Add-TodoViaADB {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("pending", "in_progress", "completed", "cancelled")]
        [string]$Status = "pending",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("low", "medium", "high", "urgent")]
        [string]$Priority = "medium",
        
        [Parameter(Mandatory=$false)]
        [string]$CategoryId = $null
    )
    
    $todoId = New-UUID
    $timestamp = Get-CurrentTimestamp
    
    # Escape single quotes in strings for SQL
    $escapedTitle = $Title -replace "'", "''"
    $escapedDescription = $Description -replace "'", "''"
    
    # Build the SQL INSERT statement
    $sql = "INSERT INTO todos (id, title, description, status, priority, category_id, created_at, updated_at, is_deleted) VALUES ('$todoId', '$escapedTitle', '$escapedDescription', '$Status', '$Priority', $(if($CategoryId) {"'$CategoryId'"} else {"NULL"}), $timestamp, $timestamp, 0);"
    
    Write-Host "Creating todo via ADB..."
    Write-Host "Title: $Title"
    Write-Host "Description: $Description"
    Write-Host "Status: $Status"
    Write-Host "Priority: $Priority"
    Write-Host ""
    
    # Create a temporary SQL file
    $tempSqlFile = "insert_todo_$todoId.sql"
    $sql | Out-File -FilePath $tempSqlFile -Encoding UTF8
    
    try {
        # Push the SQL file to the device
        adb push $tempSqlFile "/data/local/tmp/$tempSqlFile"
        
        # Execute the SQL via sqlite3 in the app's context
        $result = adb shell "run-as com.notetaking.app.note_taking_app sqlite3 databases/todo_app.db < /data/local/tmp/$tempSqlFile"
        
        # Clean up the temp file from device
        adb shell "rm /data/local/tmp/$tempSqlFile"
        
        Write-Host "✅ Todo created successfully with ID: $todoId"
        return $todoId
    }
    catch {
        Write-Host "❌ Error creating todo: $_"
        return $null
    }
    finally {
        # Clean up local temp file
        if (Test-Path $tempSqlFile) {
            Remove-Item $tempSqlFile
        }
    }
}

# Function to fetch all todos via ADB
function Get-TodosViaADB {
    Write-Host "Fetching todos via ADB..."
    
    try {
        # Query all non-deleted todos
        $result = adb shell "run-as com.notetaking.app.note_taking_app sqlite3 databases/todo_app.db 'SELECT id, title, description, status, priority, created_at FROM todos WHERE is_deleted = 0 ORDER BY updated_at DESC;'"
        
        if ($result) {
            Write-Host "📋 Found todos:"
            Write-Host "$result"
        } else {
            Write-Host "📋 No todos found in database"
        }
        
        return $result
    }
    catch {
        Write-Host "❌ Error fetching todos: $_"
        return $null
    }
}

# Function to get todo count via ADB
function Get-TodoCountViaADB {
    Write-Host "Getting todo count via ADB..."
    
    try {
        $result = adb shell "run-as com.notetaking.app.note_taking_app sqlite3 databases/todo_app.db 'SELECT COUNT(*) FROM todos WHERE is_deleted = 0;'"
        Write-Host "📊 Total todos: $result"
        return $result
    }
    catch {
        Write-Host "❌ Error getting todo count: $_"
        return $null
    }
}

# Function to delete a todo via ADB (soft delete)
function Remove-TodoViaADB {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TodoId
    )
    
    Write-Host "Deleting todo via ADB..."
    Write-Host "Todo ID: $TodoId"
    
    try {
        $timestamp = Get-CurrentTimestamp
        $result = adb shell "run-as com.notetaking.app.note_taking_app sqlite3 databases/todo_app.db \"UPDATE todos SET is_deleted = 1, updated_at = $timestamp WHERE id = '$TodoId';\""
        
        Write-Host "✅ Todo marked as deleted successfully"
        return $true
    }
    catch {
        Write-Host "❌ Error deleting todo: $_"
        return $false
    }
}

# Example usage and help
Write-Host "ADB Todo Helper Script Loaded!"
Write-Host "Available functions:"
Write-Host "  - Add-TodoViaADB -Title 'Your Title' [-Description 'Description'] [-Status 'pending'] [-Priority 'medium']"
Write-Host "  - Get-TodosViaADB"
Write-Host "  - Get-TodoCountViaADB"
Write-Host "  - Remove-TodoViaADB -TodoId 'todo-id'"
Write-Host ""
Write-Host "Example: Add-TodoViaADB -Title 'Test via ADB' -Description 'Created using ADB commands' -Priority 'high'"