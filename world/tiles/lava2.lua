-- world/tiles/lava2.lua

return {
    id = "lava2",
    name = "Lava 2", 
    colorKey = "lava2", 
    draw_style = "fill", 
    texturePath = "assets/tiles/Lava2.png",
    flags = {
        speedMod = 0.2,
        healthAffect = -20,
        interactable = true,
        interactMessage = "Extremely hot and dangerous lava!"
    }
}
