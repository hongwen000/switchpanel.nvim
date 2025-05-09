local Utils = {}

---Converts a string to a regular expression pattern
---@param pattern string The string to convert
---@return string The converted regular expression pattern
function Utils.to_regexp(pattern)
    pattern = string.gsub(pattern, "%[", "%%[")
    pattern = string.gsub(pattern, "%]", "%%]")
    pattern = string.gsub(pattern, "<.*>", "(.*)")
    return pattern
end

---Creates a deep copy of a table
---@param orig any The original value to copy
---@return any A deep copy of the original value
function Utils.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils.deepcopy(orig_key)] = Utils.deepcopy(orig_value)
        end
        setmetatable(copy, Utils.deepcopy(getmetatable(orig)))
    else
        -- For primitive types, copy directly
        copy = orig
    end
    
    return copy
end

---Merges two tables recursively
---@param t1 table The first table
---@param t2 table The second table
---@return table The merged table
function Utils.tableMerge(t1, t2)
    local result = Utils.deepcopy(t1)
    
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(result[k] or false) == "table" then
                result[k] = Utils.tableMerge(result[k] or {}, v)
            else
                result[k] = Utils.deepcopy(v)
            end
        else
            result[k] = v
        end
    end
    
    return result
end

return Utils

