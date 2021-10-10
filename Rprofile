.First = function() {
  message_wrap <- function(...) {
    message(paste(strwrap(paste(..., collapse=' ')), collapse='\n'))
  }
  wait_for_prepare_log <- function(newSession) {
    readRenviron('/opt/continuum/.Renviron')
    current_env = Sys.getenv('CONDA_DEFAULT_ENV')
    desired_env = Sys.getenv('CONDA_DESIRED_ENV')
    fpath = '/opt/continuum/prepare.log'
    cat('Active conda environment:', current_env, '\n')
    if (!file.exists(fpath)) {
      if (current_env == desired_env) {
        message_wrap(
          'NOTE: The project environment is still being prepared.',
          'If you do not wish to wait, press RETURN then ESC to exit to',
          'the command line; but note that some R packages may not yet',
          'be available for use until this process is complete.')
      } else {
        message('Requested conda environment: ', desired_env)
        message_wrap(
          'NOTE: The requested environment is still being created. Once',
          'this is complete, R will be restarted. If you do not wish to',
          'wait, press RETURN then ESC to exit to the command line; but',
          'note that you will then need to monitor the creation process',
          'yourself, and restart R manually when it is complete.')
      }
      counter = 0
      cat('Waiting...')
      while (!file.exists(fpath)) {
          Sys.sleep(0.2)
          counter = counter + 1
          if (counter == 15) {
              counter = 0
              cat('.')
              flush.console()
          }
      }
      cat('\n')
      message('Environment preparation is complete.')
      if (current_env != desired_env) {
        message('Restarting R...')
        .rs.api.restartSession()
      }
    } else if (Sys.getenv('CONDA_PROJECT_ERR') == 'yes') {
      message_wrap(
        'ERROR: an unexpected error prevented the startup script',
        'from determining the desired conda environment. This is',
        'typically caused by corruption in anaconda-project.yml.',
        'Consult the file /opt/continuum/prepare.log for details.')
    } else if (current_env != desired_env) {
      message('Requested conda environment: ', desired_env)
      message_wrap(
        'ERROR: The project preparation stage is complete, but the',
        'requested conda environment does not have an R interpreter.',
        'This is either because the anaconda-project.yml file does',
        'not specify an r-base package, or there was an error during',
        'preparation. Consult the file /opt/continuum/prepare.log',
        'for more details.')
    }
  }
  if (Sys.getenv("RSTUDIO") == "1") {
    setHook("rstudio.sessionInit", wait_for_prepare_log, action="append")
  }
}
