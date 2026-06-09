using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
        "--port"
            help = "the http port the server is listening to"
            arg_type = Int
            default = 8002
        "--logfile"
            help = "the name (and path) of the logfile. If not specified logging is done on stderr."
            arg_type = String
            default = ""
        "--no_logging"
            help = "switch of logging completely"
            action = :store_true
    end
    return parse_args(s)
end

