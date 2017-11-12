# NLGetAgentSet rewrite for NetLogo6
NLGetAgentSet1 <- function(agent.var, agentset) {
  tmp <-
    NLReport(paste("map [i -> [", agent.var, "] of i] sort", agentset))
  names(tmp) <- agent.var
  tmp %>% dplyr::as_data_frame()
}

# NLGetPatches rewrite for NetLogo6 (do not t)
NLGetPatches1 <- function(patch.var, patchset) {
  NLReport(paste("map [ i -> [", patch.var, "] of i] sort", patchset)) %>% matrix(NLReport("world-width"))
}
