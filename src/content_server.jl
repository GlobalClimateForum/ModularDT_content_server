module OxygenContentServer

using Oxygen
using HTTP
using JSON3
using Dates
using Logging, LoggingExtras
using CSV
using DataFrames
using VegaLite, VegaDatasets
using DotEnv

# maybe make configurable?
# Read the CONTENT_DIR from the .env file if it exists
DotEnv.load!()
if haskey(ENV, "CONTENTDIR")
    global CONTENT_DIR = abspath(ENV["CONTENTDIR"])
else
    global CONTENT_DIR = abspath(joinpath(@__DIR__, "content"))
    println("$(@__DIR__)")
end

include("./tools/tools.jl")
include("./tools/endpoint_tools.jl")
include("./themes/theme_ggplot2.jl")

include("./endpoints/endpoint_file.jl")
include("./endpoints/endpoints_server_health.jl")
include("./endpoints/user_defined_endpoints/dt_diva/endpoint_diva_line_plot.jl")
include("parse_arguments.jl")
include("setup_logging.jl")

parsed_args = parse_commandline()
setup_logging(parsed_args)
@info "listening on port: $(parsed_args["port"])"

# Define all alowed origins for CORS
const ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "http://127.0.0.1:5173", 
    "http://localhost:8000", 
    "http://127.0.0.1:8000"
]

# Get the CORS headers for a given request - if the origin is allowed, return the appropriate headers
# , otherwise return empty headers
function cors_headers(req::HTTP.Request)
    origin = HTTP.header(req, "Origin", "")
    allowed = origin in ALLOWED_ORIGINS ? origin : ""
    
    # Debug logging
    if isempty(allowed) && !isempty(origin)
        @warn "CORS origin not allowed" origin allowed_origins=ALLOWED_ORIGINS
    end
    
    return [
        "Access-Control-Allow-Origin" => allowed,
        "Access-Control-Allow-Headers" => "*",
        "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
        "Vary" => "Origin",
    ]
end
# Define a middleware function to handle CORS preflight requests and add CORS headers to responses
function CorsMiddleware(handler)
    return function(req::HTTP.Request)
        cors_header = cors_headers(req)
        if HTTP.method(req) == "OPTIONS"
            return HTTP.Response(200, cors_header)   # answer preflight directly
        end
        response = handler(req) # Get the response from the original handler
        append!(response.headers, cors_header) # Add CORS headers to the response
        return response # Return the modified response
    end
end

# Server auf Port port starten
serve(middleware=[CorsMiddleware], port=parsed_args["port"])

end # module content_server
