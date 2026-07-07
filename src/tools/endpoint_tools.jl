function write_progress(stream, value, message)
  payload = (
    progress=value,
    timestamp=now(),
    state=message
  )   
  # as JSON 
  json_string = JSON3.write(payload) |> x -> replace(x, "\n" => "") |> x -> replace(x, " " => "")
  write(stream, "data: $json_string\n\n")
end
