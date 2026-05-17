local Registry = {
    entities = {},
    nextId = 1,
    queryCache = {}
}

function Registry.create()
    local id = Registry.nextId
    Registry.nextId = Registry.nextId + 1
    Registry.entities[id] = {}
    return id
end

function Registry.add(id, componentName, data)
    Registry.entities[id][componentName] = data or {}
    
    local toRemove = {}
    for sig, _ in pairs(Registry.queryCache) do
        if string.find(sig, componentName) then
            table.insert(toRemove, sig)
        end
    end
    for _, sig in ipairs(toRemove) do
        Registry.queryCache[sig] = nil
    end
end

function Registry.remove(id)
    local comps = Registry.entities[id]
    if not comps then return end
    
    local toRemove = {}
    for sig, _ in pairs(Registry.queryCache) do
        for compName, _ in pairs(comps) do
            if string.find(sig, compName) then
                toRemove[sig] = true
            end
        end
    end
    for sig in pairs(toRemove) do
        Registry.queryCache[sig] = nil
    end
    
    Registry.entities[id] = nil
end

function Registry.get(id, componentName)
    return Registry.entities[id] and Registry.entities[id][componentName]
end

function Registry.has(id, componentName)
    return Registry.entities[id] and Registry.entities[id][componentName] ~= nil
end

function Registry.query(...)
    local req = {...}
    local sig = table.concat(req, "|")
    
    if Registry.queryCache[sig] then
        return Registry.queryCache[sig]
    end

    local result = {}
    for id, comps in pairs(Registry.entities) do
        local match = true
        for _, c in ipairs(req) do
            if not comps[c] then match = false; break end
        end
        if match then table.insert(result, id) end
    end
    
    table.sort(result) -- Sort to guarantee deterministic draw/update order
    Registry.queryCache[sig] = result
    return result
end

function Registry.queryCached(sig, reqArray)
    if Registry.queryCache[sig] then
        return Registry.queryCache[sig]
    end

    local result = {}
    for id, comps in pairs(Registry.entities) do
        local match = true
        for _, c in ipairs(reqArray) do
            if not comps[c] then match = false; break end
        end
        if match then table.insert(result, id) end
    end
    
    table.sort(result)
    Registry.queryCache[sig] = result
    return result
end

function Registry.clear()
    Registry.entities = {}
    Registry.nextId = 1
    Registry.queryCache = {}
end

return Registry
