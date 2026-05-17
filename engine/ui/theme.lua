local Theme = {
    colors = {
        background = {0.05, 0.05, 0.05, 1},
        surface    = {0.1,  0.1,  0.1,  1},
        hover      = {0.15, 0.15, 0.15, 1},
        pressed    = {0.08, 0.08, 0.08, 1},
        
        border       = {0.3, 0.3, 0.3, 1},
        borderHover  = {0.5, 0.5, 0.5, 1},
        borderActive = {0.9, 0.9, 0.9, 1},
        
        text       = {0.9, 0.9, 0.9, 1},
        textMuted  = {0.5, 0.5, 0.5, 1},
        
        selection  = {0.3, 0.3, 0.3, 1},
        cursor     = {0.9, 0.9, 0.9, 1},
    },
    
    font = nil, -- to be set by the host application
    fontSmall = nil,
    
    metrics = {
        padding = 8,
        borderWidth = 1,
    }
}

return Theme
