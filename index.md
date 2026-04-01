---
layout: default
title: "llmdist: Distance Computation for Multivariate Normal Distributions"
---

<div class="row">
    <div class="col-md-8">
        <h1>{{ site.title }}</h1>
        <p class="lead">{{ site.description }}</p>
        
        <hr>
        
        <h2>Latest Posts</h2>
        
        {% for post in site.posts %}
        <article class="mb-4">
            <h3><a href="{{ post.url | relative_url }}" class="text-decoration-none">{{ post.title }}</a></h3>
            <p class="post-meta">
                <small class="text-muted">{{ post.date | date: "%B %d, %Y" }} by {{ post.author }}</small>
            </p>
            <p>{{ post.excerpt }}</p>
            <a href="{{ post.url | relative_url }}" class="btn btn-primary btn-sm">Read More</a>
        </article>
        <hr>
        {% endfor %}
        
        {% if site.posts.size == 0 %}
        <p class="text-muted">No posts yet. Check back soon!</p>
        {% endif %}
    </div>
    
    <div class="col-md-4">
        <div class="card">
            <div class="card-header">
                <h5 class="mb-0">Package Info</h5>
            </div>
            <div class="card-body">
                <p><strong>llmdist</strong> provides efficient distance computation between multivariate normal distributions.</p>
                
                <h6>Key Features:</h6>
                <ul class="list-unstyled">
                    <li>✅ First Fisher-Rao implementation</li>
                    <li>✅ 50x faster LRT trace distance</li>
                    <li>✅ 8 different distance methods</li>
                    <li>✅ High-dimensional support</li>
                </ul>
                
                <hr>
                
                <h6>Installation:</h6>
                <pre><code class="language-r">devtools::install_github("svanteE/llmdist")</code></pre>
                
                <hr>
                
                <div class="d-grid gap-2">
                    <a href="https://github.com/svanteE/llmdist" class="btn btn-outline-dark btn-sm">
                        📁 GitHub Repository
                    </a>
                    <a href="#" class="btn btn-outline-secondary btn-sm">
                        📖 Documentation
                    </a>
                </div>
            </div>
        </div>
        
        <div class="card mt-3">
            <div class="card-header">
                <h6 class="mb-0">Categories</h6>
            </div>
            <div class="card-body">
                <span class="badge bg-primary me-1">R</span>
                <span class="badge bg-secondary me-1">Statistics</span>
                <span class="badge bg-success me-1">Machine Learning</span>
                <span class="badge bg-info">Performance</span>
            </div>
        </div>
    </div>
</div>