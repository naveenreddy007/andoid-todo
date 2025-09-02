# Test Tag Functionality via ADB
Write-Host "🔍 Testing Tag Database via ADB" -ForegroundColor Cyan

# Database path on device
$dbPath = "/data/data/com.notetaking.app.note_taking_app/databases/todo_app.db"

Write-Host "`n📱 Checking if app database exists..." -ForegroundColor Yellow
$dbExists = adb shell "test -f $dbPath && echo 'exists' || echo 'not found'"
Write-Host "Database status: $dbExists"

if ($dbExists -eq "exists") {
    Write-Host "`n✅ Database found! Testing tag functionality..." -ForegroundColor Green
    
    Write-Host "`n🔍 Checking tags table schema..." -ForegroundColor Yellow
    adb shell "sqlite3 $dbPath 'PRAGMA table_info(tags);'"
    
    Write-Host "`n🔍 Checking todo_tags table schema..." -ForegroundColor Yellow
    adb shell "sqlite3 $dbPath 'PRAGMA table_info(todo_tags);'"
    
    Write-Host "`n🏷️ Current tags in database:" -ForegroundColor Yellow
    adb shell "sqlite3 $dbPath 'SELECT id, name, color FROM tags;'"
    
    Write-Host "`n📝 Current todos (first 5):" -ForegroundColor Yellow
    adb shell "sqlite3 $dbPath 'SELECT id, title FROM todos LIMIT 5;'"
    
    Write-Host "`n🔗 Todo-tag associations:" -ForegroundColor Yellow
    adb shell "sqlite3 $dbPath 'SELECT todo_id, tag_id FROM todo_tags;'"
    
    Write-Host "`n➕ Testing tag creation..." -ForegroundColor Yellow
    $testTagId = "test_tag_$(Get-Date -Format 'yyyyMMddHHmmss')"
    $testTagName = "ADB Test Tag"
    $testTagColor = "#FF5722"
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    
    $insertQuery = "INSERT INTO tags (id, name, color, created_at) VALUES ('$testTagId', '$testTagName', '$testTagColor', '$timestamp');"
    Write-Host "Executing: $insertQuery"
    
    $insertResult = adb shell "sqlite3 $dbPath \"$insertQuery\""
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Test tag created successfully!" -ForegroundColor Green
        
        Write-Host "`n🔍 Verifying test tag creation..." -ForegroundColor Yellow
        adb shell "sqlite3 $dbPath 'SELECT id, name, color FROM tags WHERE id = \"$testTagId\";'"
        
        Write-Host "`n🧹 Cleaning up test tag..." -ForegroundColor Yellow
        adb shell "sqlite3 $dbPath 'DELETE FROM tags WHERE id = \"$testTagId\";'"
        Write-Host "✅ Test tag cleaned up!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create test tag" -ForegroundColor Red
    }
    
    Write-Host "`n📊 Final tag count:" -ForegroundColor Yellow
    adb shell "sqlite3 $dbPath 'SELECT COUNT(*) as tag_count FROM tags;'"
    
} else {
    Write-Host "❌ Database not found. App may not be installed or initialized." -ForegroundColor Red
}

Write-Host "`n✅ Tag database test completed!" -ForegroundColor Green