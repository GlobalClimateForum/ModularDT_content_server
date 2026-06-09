using HTTP
using JSON3, JSON
using URIs
using BufferedStreams
using VegaLite

# URL of the running Oxygen servers
url_json = "http://127.0.0.1:8002/json"
url_png = "http://127.0.0.1:8002/file?path=./png/hintergrund.png"
url_time_series_diva = "http://127.0.0.1:8002/diva_line_plot"

url_time_series_diva_params = Dict(
    "data" => "./data/diva_runs_country.csv",
    "filter[locationid]" => "GBR",
    "filter[ssp]" => "SSP2",
    "filter[rcp]" => "370",
    "filter[quantile]" => "0.95",
    "filter[adaptation]" => "Optimal protection",
    "filter[migration]" => "false",
    "x" => "time",
    "y" => "expected_annual_damages"
)


function test_png()
  try
    # GET-request
    response = HTTP.get(url_png)

    # 3. Status prüfen und Body verarbeiten
    if response.status == 200
      println(typeof(response.body))
      outfile = open("testfile.png", "w")
      write(outfile, response.body)
      close(outfile)
    end
  catch e
    println("Connection error: ", e)
  end
end

function test_time_series_diva()

  println("Connect to server...")

  # Wir übergeben einen Callback, der bei jedem neuen Event (Zeile) aufgerufen wird
  try
    full_url_time_series_diva = string(URI(URI(url_time_series_diva); query = url_time_series_diva_params))

    HTTP.open("GET", full_url_time_series_diva) do stream
      # Checke Statuscode (bevor wir den Body lesen)
      resp = startread(stream)
      if resp.status != 200
        println("Error: ", String(read(stream)))
        return
      end
      println("connected with JSON-Stream...")

      buffered_stream = BufferedInputStream(stream)

      while !eof(stream)
        line = readline(stream)

        # Prüfen, ob die Zeile Daten enthält
        if startswith(line, "progress: ")
          json_raw = replace(line, "progress: " => "")

          # parse JSON-String 
          data = JSON3.read(json_raw)

          println("Received: $(data.progress*100) percent. State: $(data.state)")

          # Zugriff auf die Felder
          if haskey(data, :state) && data.state == "finished"
            println("Server finished processing of data.")
          end
        end
        if startswith(line, "plot: ")
          json_raw = replace(line, "plot: " => "")
          plot_data = JSON3.read(json_raw)
	  vl_plot = VegaLite.VLSpec(plot_data)
#	  vl_plot
	  save("plot.svg", vl_plot)
          return
	end
      end
    end
  catch e
    #if e isa InterruptException || e isa EOFError || (e isa HTTP.Exceptions.RequestError && occursin("INVALID_CHUNK_SIZE", string(e)))
    #  println("\nServer stopped.")
    #else
      println("streaming error: ", e)
    #end
  end
end

test_png()
test_time_series_diva()
