local Event = {
    listeners = {}
}

function Event.on(eventName, callback)
    if not Event.listeners[eventName] then
        Event.listeners[eventName] = {}
    end
    table.insert(Event.listeners[eventName], callback)
end

function Event.fire(eventName, ...)
    if Event.listeners[eventName] then
        for _, callback in ipairs(Event.listeners[eventName]) do
            callback(...)
        end
    end
end

function Event.off(eventName, callback)
    if not Event.listeners[eventName] then return end
    for i, cb in ipairs(Event.listeners[eventName]) do
        if cb == callback then
            table.remove(Event.listeners[eventName], i)
            break
        end
    end
end

return Event
