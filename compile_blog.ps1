# PowerShell script to compile blog post
Write-Host "Compiling blog post to HTML..." -ForegroundColor Green
pandoc blog_post_r_bloggers.md -o blog_post_r_bloggers.html --standalone --embed-resources

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Successfully compiled!" -ForegroundColor Green
    Write-Host "Opening in browser..." -ForegroundColor Yellow
    Start-Process blog_post_r_bloggers.html
} else {
    Write-Host "❌ Compilation failed!" -ForegroundColor Red
}

Read-Host "Press Enter to continue"