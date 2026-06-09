module OxygenContentServer

using Oxygen
using HTTP
using JSON3
using Dates
using Logging, LoggingExtras
using CSV
using DataFrames
using VegaLite, VegaDatasets

# maybe make configurable?
const CONTENT_DIR = abspath("/home/lincke/Repositories/decision-theatre/modularDT/ModularDT_content_server/content/")

include("./tools/tools.jl")
include("./tools/endpoint_tools.jl")
include("./themes/theme_ggplot2.jl")

include("./endpoints/endpoint_file.jl")
include("./endpoints/user_defined_endpoints/dt_diva/endpoint_diva_line_plot.jl")
include("parse_arguments.jl")
include("setup_logging.jl")

parsed_args = parse_commandline()
setup_logging(parsed_args)
@info "listening on port: $(parsed_args["port"])"

# Server auf Port port starten
serve(port=parsed_args["port"])

end # module content_server
