.First = function() {
  wait_for_prepare_log <- function(newSession) {
    readRenviron('/opt/continuum/.Renviron')
    current_env = Sys.getenv('CONDA_DEFAULT_ENV')
    desired_env = Sys.getenv('CONDA_DESIRED_ENV')
    fpath = '/opt/continuum/prepare.log'
    if (!file.exists(fpath)) {
      if (current_env == desired_env) {
        message('NOTE: The project environment is still being prepared.')
        message('Some R packages may not be available until this is complete.')
      } else {
        message('Requested conda environment: ', desired_env)
        message('NOTE: The requested environment is still being created.')
        message('Once the creation step is complete, R must be restarted.')
        message('If you wish to wait, this will be done automatically. If')
        message('you do not, press RETURN then ESC to exit to the command')
        message('line. You will then need to restart R manually once the')
        message('conda environment has finished preparing.')
        counter = 0
        cat('Waiting...')
        while (!file.exists(fpath)) {
            Sys.sleep(0.1)
            counter = counter + 1
            if (counter == 30) {
                counter = 0
                cat('.')
                flush.console()
            }
        }
        cat('\n')
        message('Environment preparation is complete; restarting...')
        .rs.api.restartSession()
      }
    } else if (current_env != desired_env) {
      message('Requested conda environment: ', desired_env)
      message('ERROR: The project preparation stage is complete, but the')
      message('requested conda environment does not have an R interpreter.')
      message('This is either because the environment specification in the')
      message('file anaconda-project.yml does not include the r-base package,')
      message('or there was an error during preparation. In the latter case,')
      message('consult the file /opt/continuum/prepare.log for details.')
    }
  }
  if (Sys.getenv("RSTUDIO") == "1") {
    setHook("rstudio.sessionInit", wait_for_prepare_log, action="append")
  }
}
cat('Active conda environment:', Sys.getenv('CONDA_DEFAULT_ENV'), '\n')
