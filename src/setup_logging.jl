# set up logging - either stderr or to a file or to nirvana (devnull)
function setup_logging(parsed_args)
  if !parsed_args["no_logging"]
    io = if isempty(parsed_args["logfile"])
      logger = SimpleLogger(stderr)
      global_logger(logger)
    else
      logger = FileLogger(parsed_args["logfile"]; append=false, always_flush=true)
      global_logger(logger)
    end

    if isempty(parsed_args["logfile"]) 
      @info "logging to stderr"
    else
      @info "logging to $(parsed_args["logfile"])"
    end
  else
    logger = SimpleLogger(devnull)
    global_logger(logger)
  end
end


