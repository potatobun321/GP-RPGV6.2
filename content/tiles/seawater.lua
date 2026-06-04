-- content/tiles/seawater.lua

return {
    id = "seawater",
    name = "Seawater", 
    colorKey = "seawater", 
    draw_style = "fill", 
    texturePath = "content/tiles/Seawater.png",
    flags = {
        speedMod = 0.5,
        interactable = true,
        interactMessage = "Deep, salty seawater."
    }
}
