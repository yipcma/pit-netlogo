# install.packages("rJava", repos = c(CRAN = "https://cran.revolutionanalytics.com"))

library(tidyverse)
library(RNetLogo)

setwd("~/repos/Netlogos-Projects/pit-netlogo/")
basepath <- "/Applications/NetLogo 6.0.2/"
nl.path <- "/Applications/NetLogo 6.0.2/Java/"

NLStart(nl.path, gui = F, is3d = F, nl.jarname = "netlogo-6.0.2.jar")
model.path <- file.path("models", "Sample Models", "Earth Science", "Fire.nlogo")
NLLoadModel(file.path(basepath, model.path))

NLCommand("set density 77")
NLCommand("setup")
NLCommand("go")
NLCommand("print \"Hello NetLogo, I called you from R.\"")

density.in.r <- 88
NLCommand("set density ", density.in.r, "setup", "go")
NLDoCommand(10, "go")
NLReport("ticks")

NLQuit()
