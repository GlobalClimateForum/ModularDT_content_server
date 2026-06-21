@get "/ping" function(req::HTTP.Request)
    println("return pong")
    return "pong"
end

@get "/health" function()
    return Dict(
        "status" => "online",
        "message" => "server is running smoothly",
        "timestamp" => time()
    )
end
