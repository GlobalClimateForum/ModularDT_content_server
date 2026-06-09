@get "/html" function(req::HTTP.Request)
    return html("<h1>Hallo Oxygen</h1><p>This is a HTML-response.</p>")
end

# Dict is serialised automatically
@get "/json" function(req::HTTP.Request)
    return json(Dict("state" => "success", "data" => [10, 20, 30]))
end

# 4. SSE-Endpunkt für Fortschrittsmeldungen
# Nutze HTTP.Stream als Argument-Typ, damit Oxygen weiß, dass es ein Stream ist
#@openapi Default(exclude=true) # Versteckt die folgende Route vor Swagger/OpenAPI
@stream "/huge_thing" function(stream::HTTP.Stream; request)

    params = queryparams(request)

    # Header direkt auf dem Stream setzen
    HTTP.setheader(stream, "Content-Type" => "text/event-stream")
    HTTP.setheader(stream, "Cache-Control" => "no-cache")
    HTTP.setheader(stream, "Connection" => "keep-alive")

    # Important: send header before data
    HTTP.startwrite(stream)

    for i in 1:10
        sleep(1)
        
        # Ein Julia-Objekt (Named Tuple) erstellen
	if i<=9 
          payload = (
            schritt = i,
            zeitstempel = now(),
            status = "verarbeite",
            daten = [rand(), rand(), rand()]
          ) 
          # In JSON umwandeln und als SSE-Event senden
          # Wichtig: JSON darf keine Zeilenumbrüche enthalten (\n)
          json_string = JSON3.write(payload)
          write(stream, "data: $json_string\n\n")
	else
          payload = (
            schritt = i,
            zeitstempel = now(),
            status = "beendet",
            daten = [rand(), rand(), rand()]
          ) 
          # In JSON umwandeln und als SSE-Event senden
          # Wichtig: JSON darf keine Zeilenumbrüche enthalten (\n)
          json_string = JSON3.write(payload)
          write(stream, "data: $json_string\n\n")
	end
    end

end

