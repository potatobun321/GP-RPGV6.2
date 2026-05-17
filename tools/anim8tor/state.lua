local state = {
    image = nil,
    fileData = nil,
    grid = nil,
    animation = nil,
    
    font = nil,
    fontSmall = nil,
    
    screenW = 0,
    screenH = 0,
    
    generatedCode = "",
    errorMessage = "",
    
    selectedFrames = {},
    
    selectedTemplate = "walk_down",
    savedSlots = {},
    
    inputState = {
        frameWidth = {text = "64"},
        frameHeight = {text = "64"},
        left = {text = "0"},
        top = {text = "0"},
        border = {text = "0"},
        duration = {text = "0.1"},
        entityType = {text = "player"},
        exportName = {text = "walk_down"}
    }
}

return state
