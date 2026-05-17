-- world/tiles/sand.lua

return {
    id = "sand",
    name = "Sand", 
    colorKey = "sand", 
    draw_style = "fill", 
    texturePath = "assets/tiles/Sand.png",
    flags = {
        speedMod = 0.7,
        interactable = true,
        interactMessage = "Soft, shifting sand."
    }
}
