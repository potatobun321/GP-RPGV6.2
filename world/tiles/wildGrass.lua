-- world/tiles/wildGrass.lua

return {
    id = "wildGrass",
    name = "Wild Grass", 
    colorKey = "wildGrass", 
    draw_style = "fill", 
    texturePath = "assets/tiles/wildGrass.png",
    flags = {
        speedMod = 0.8,
        interactable = true,
        interactMessage = "Thick, overgrown wild grass."
    }
}
