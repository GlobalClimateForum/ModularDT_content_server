function write_progress(stream, value, message)
  payload = (
    progress=value,
    timestamp=now(),
    state=message
  )   
  # as JSON 
  json_string = JSON3.write(payload)
  write(stream, "progress: $json_string\n\n")
end
