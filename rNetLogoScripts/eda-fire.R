# chapter 4 exploratory analysis with fire.nlogo

library(tidyverse)
library(RNetLogo)

nl.path <- "/Applications/NetLogo 6.0.2/Java/"
NLStart(nl.path, gui = F, nl.jarname = "netlogo-6.0.2.jar")
model.path <- "/Users/yipc/repos/Netlogos-Projects/pit-netlogo/testFire.nlogo"
NLLoadModel(model.path)

sim <- function(density) {
  NLCommand("set density", density, "setup")
  NLDoCommandWhile("any? turtles", "go")
  NLReport("(burned-trees / initial-trees) * 100")
}

rep.sim <- function(density, rep) {
  names(density) <- density
  lapply(density, function(dens) replicate(rep, sim(dens))) %>% dplyr::as_data_frame()
}

# one sim
percentBurned <- sapply(1:100, sim)

data_frame(x = 1:100, y = percentBurned) %>% ggplot(aes(x, y)) + geom_point()

# repeated sims
res <- rep.sim(seq(45, 70, 5), 10)
res %>% dplyr::as_data_frame() %>% gather(density, percentBurned) %>% ggplot(aes(density, percentBurned)) + geom_boxplot()

# further repeated sims at higher resolution and more runs
# BUG: slow sims (super fast in behaviorSpace after disabling updates)

res1 <- rep.sim(55:65, 20)
res1 %>% dplyr::as_data_frame() %>% gather(density, percentBurned) %>% ggplot(aes(density, percentBurned)) + geom_boxplot()


NLQuit()
