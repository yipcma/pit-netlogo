# install.packages("rJava", repos = c(CRAN = "https://cran.revolutionanalytics.com"))

library(tidyverse)
library(RNetLogo)

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
NLDoCommandWhile("ticks < 20", "go")
NLReport("ticks")

# NLGetAgentSet rewrite for NetLogo6
NLGetAgentSet1 <- function(agent.var, agentset) {
  tmp <- NLReport(paste("map [i -> [", agent.var, "] of i] sort", agentset))
  names(tmp) <- agent.var
  tmp %>% dplyr::as_data_frame()
}

test <- NLGetAgentSet1(c("who", "color"), "fires")

# simulation

NLQuit()
