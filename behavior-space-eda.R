# behaviorSpace eda script for fire

library(tidyverse)

results <- read_csv("testFire experiment-table.csv", skip = 6)

names(results) <- c("runId", "density", "steps", "burnedPercent")

results %>% ggplot(aes(x = density, y = burnedPercent, group = density)) + geom_violin(draw_quantiles = c(0.25, 0.5, 0.75))
