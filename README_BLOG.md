# llmdist Blog

A Jekyll blog for the llmdist R package hosted on GitHub Pages.

## ✅ Setup Complete!

Your blog is ready to go. Just enable GitHub Pages:

### 🚀 Enable GitHub Pages (One-time setup):

1. **Go to your repository settings:** https://github.com/svanteE/llmdist/settings/pages

2. **Configure Pages:**
   - **Source:** "Deploy from a branch"
   - **Branch:** "main" 
   - **Folder:** "/ (root)"
   - Click **"Save"**

3. **Your blog will be live at:** `https://svanteE.github.io/llmdist/`

### 📝 No Custom Workflows Needed!

GitHub automatically builds and deploys Jekyll sites from the main branch. No custom GitHub Actions required.

## File Structure

```
├── _config.yml          # Jekyll configuration
├── _layouts/
│   └── default.html     # Main page layout
├── _posts/
│   └── 2026-04-01-llmdist-package-introduction.md  # Your blog post
├── index.md            # Homepage
├── Gemfile            # GitHub Pages compatible dependencies
└── .jekyllignore      # Files to exclude from Jekyll build
```

## Writing New Posts

1. Create new files in `_posts/` with format: `YYYY-MM-DD-title.md`
2. Add YAML front matter at the top:
   ```yaml
   ---
   layout: default
   title: "Your Post Title"
   date: 2026-04-01
   author: "Svante Eriksen"
   categories: [R, statistics]
   tags: [your-tags]
   excerpt: "Brief description"
   ---
   ```
3. Write your content in Markdown below the front matter

## Local Development (Optional)

To preview locally:
```bash
# Install Jekyll
gem install jekyll bundler

# Create Gemfile
echo 'source "https://rubygems.org"' > Gemfile
echo 'gem "jekyll", "~> 4.0"' >> Gemfile
echo 'gem "minima"' >> Gemfile

# Install dependencies and serve
bundle install
bundle exec jekyll serve

# View at http://localhost:4000
```

## Customization

- Edit `_config.yml` for site settings
- Modify `_layouts/default.html` for design changes  
- Update `index.md` for homepage content
- Add custom CSS in the `<style>` section of `default.html`

## Next Steps for R-bloggers

Once your GitHub Pages blog is live:
1. **Apply to R-bloggers** at https://www.r-bloggers.com/add-your-blog/
2. **Provide your RSS feed**: `https://svanteE.github.io/llmdist/feed.xml`
3. **Wait for approval** - they'll review and add you to their aggregation
4. **Future posts** will automatically appear on R-bloggers!