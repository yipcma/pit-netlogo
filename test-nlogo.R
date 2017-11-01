# install.packages("rJava", repos = c(CRAN = "https://cran.revolutionanalytics.com"))

library(tidyverse)
library(RNetLogo)

source("helpers.R")
basepath <- "/Applications/NetLogo 6.0.2/"
nl.path <- "/Applications/NetLogo 6.0.2/Java/"

NLStart(nl.path,
        gui = F,
        is3d = F,
        nl.jarname = "netlogo-6.0.2.jar")
# model.path <- file.path("models", "Sample Models", "Earth Science", "Fire.nlogo")
# NLLoadModel(file.path(basepath, model.path))
NLLoadModel("/Users/yipc/repos/Netlogos-Projects/pit-netlogo/testFire.nlogo")

# simulation
simFire <- function(density) {
  NLCommand(paste("set density", density), "setup")
  NLDoReportWhile(
    "any? turtles",
    "go",
    c("ticks", "burned-trees / initial-trees"),
    as.data.frame = T,
    df.col.names = c("tick", "burnedFraction")
  )
}

simFire(50)

testAgentSet <- NLGetAgentSet1(c("who", "color / 15"), "fires")

testPatches <- NLGetPatches1("pcolor", "patches")

library(rasterVis)
levelplot(testPatches)

NLQuit()
