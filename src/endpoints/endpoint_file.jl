# general HTTP endpoint for all kind of files on the server
# supports parameter '?path=...'
# absolute paths/specific content-directory is used 
@get "/file" function(req::HTTP.Request)

    params = queryparams(req)
    # get file path 
    requested_path = get(params, "path", "") 
    @debug "requested_path = @requested_path"

    # absolute path 
    full_path = abspath(joinpath(CONTENT_DIR, requested_path))
    @debug "full_path = @full_path"

    # check: does the full absolute path start with the CONTENT_DIR?
    if !startswith(full_path, CONTENT_DIR)
        return HTTP.Response(403, "Access denied: Invalid path")
    end

    # check if file exists
    if !isfile(full_path)
        return HTTP.Response(404, "File not found")
    end

    return file(full_path)
end

