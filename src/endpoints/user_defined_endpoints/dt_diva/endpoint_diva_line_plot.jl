const ALLOWED_ORIGINS = [
    "http://localhost:5173",
    "http://127.0.0.1:5173", 
    "http://localhost:8000", 
    "http://127.0.0.1:8000"
]

function set_cors!(stream::HTTP.Stream)
    origin = HTTP.header(stream.message, "Origin", "")
    allowed = origin in ALLOWED_ORIGINS ? origin : ""
    HTTP.setheader(stream, "Access-Control-Allow-Origin" => allowed)
    HTTP.setheader(stream, "Vary" => "Origin")
end

# route for a time series plot with progress report
@stream "/diva_line_plot" function (stream::HTTP.Stream)

    request = stream.message
    params = queryparams(request)
    #println(params)

    filters = sub_dictionary(params, "filter") 
    #println(filters)

    # 1. path, fallback
    requested_data_file = get(params, "data", "")
    @debug "requested_data_file = @requested_data_file"

    # 2. absolute path 
    full_path = abspath(joinpath(CONTENT_DIR, requested_data_file))
    @debug "full_path = @full_path"

    # 3. check: does the full absolute path start with the CONTENT_DIR?
    if !startswith(full_path, CONTENT_DIR)
        HTTP.setstatus(stream, 403)
        set_cors!(stream)
        HTTP.startwrite(stream)  
        write(stream, "Access denied: Invalid path")
        return
    end

    # 4. check if file exists
    if !isfile(full_path)
        HTTP.setstatus(stream, 404)
        set_cors!(stream)
        HTTP.startwrite(stream)
        write(stream, "File not found")
        return
    end

    # Write header in stream
    HTTP.setheader(stream, "Content-Type" => "text/event-stream")
    HTTP.setheader(stream, "Cache-Control" => "no-cache")
    # HTTP.setheader(stream, "Connection" => "keep-alive")
    set_cors!(stream) 
    HTTP.startwrite(stream)

    df = DataFrame()
    try
        df = DataFrame(CSV.File(full_path))
        if length(filters)>0
	    write_progress(stream, 1/(length(filters)+1), "process")
        else 
	    write_progress(stream, 1.0, "finished")
        end
    catch e
        println(e)
        HTTP.setstatus(stream, 452)
        set_cors!(stream)
        HTTP.startwrite(stream)
        write(stream, "File " * requested_data_file * " exists, but no valid csv format detected")
        return
    end

    i=2.0

    try
	for (filter_key, filter_value) in filters
            sleep(0.2)
	    df = df[df[!, filter_key] .== filter_value, :]
            if i/(length(filters)+1)<1.0 
		write_progress(stream, i/(length(filters)+1), "process")
            else 
		write_progress(stream, 1.0, "finished")
	    end
	    i = i + 1
	end

	# build the plot 
        p = df |> @vlplot(:line, x=(params["x"]), y=(params["y"]),config=theme_ggplot2)
        
	# and convert into json. Need to used the json-parser from VegaLite, otherwise the result might not be correct
	json_string = VegaLite.json(p) |> x -> replace(x, "\n" => "") |> x -> replace(x, " " => "")
        write(stream, "data: $json_string\n\n")
        flush(stream)
    catch e
        @error "Streaming error" exception=(e, catch_backtrace())
    end
end
