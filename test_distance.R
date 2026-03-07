devtools::load_all()
result <- fisher_rao_distance(c(0,0,0), diag(1,3), c(1,1,1), matrix(c(1, 0.1, 0.1, .1,1,.1,.1,.1,1), 3, 3))
print(result)
