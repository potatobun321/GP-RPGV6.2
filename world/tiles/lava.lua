-- world/tiles/lava.lua

return {
    id = "lava",
    name = "Lava", 
    colorKey = "lava", 
    draw_style = "fill", 
    texturePath = "assets/tiles/lava.png",
    flags = {
        speedMod = 0.2,
        healthAffect = -5,
        interactable = true,
        interactMessage = "Ouch! It's boiling hot lava!"
    }
}
