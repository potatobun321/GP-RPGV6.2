-- content/tiles/water.lua

return {
    id = "water",
    name = "Water", 
    colorKey = "water", 
    draw_style = "fill", 
    texturePath = "content/tiles/water.png",
    flags = {
        speedMod = 0.6,
        interactable = true,
        interactMessage = "Clear, fresh water."
    }
}
