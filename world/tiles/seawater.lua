-- world/tiles/seawater.lua

return {
    id = "seawater",
    name = "Seawater", 
    colorKey = "seawater", 
    draw_style = "fill", 
    texturePath = "assets/tiles/Seawater.png",
    flags = {
        speedMod = 0.5,
        interactable = true,
        interactMessage = "Deep, salty seawater."
    }
}
