# parse arbitrary values 
function parse_val(v)
    v_lower = lowercase(v)
    if v_lower == "true" return true end
    if v_lower == "false" return false end
    
    # parse number (Float or Int), if not possible keep String
    val = tryparse(Int, v)
    isnothing(val) && (val = tryparse(Float64, v))
    return isnothing(val) ? v : val
end

function sub_dictionary(dict, prefix) 
    pattern = Regex("^$(prefix)\\[(.*)\\]")
    return Dict(replace(k, pattern => s"\1") => parse_val(v) for (k, v) in dict if occursin(pattern, k))
end
