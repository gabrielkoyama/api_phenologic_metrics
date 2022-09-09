library(plumber)
options(warn=-1)

r <- plumber::plumb("metrics.R")
r$run(port=8080, host="0.0.0.0",swagger=TRUE)
