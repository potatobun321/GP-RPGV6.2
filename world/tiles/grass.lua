-- world/tiles/grass.lua

return {
    id = "grass",
    name = "Grass", 
    colorKey = "grass", 
    draw_style = "fill", 
    texturePath = "assets/tiles/grass.png",
    flags = {
        interactable = true,
        interactMessage = "Just some ordinary grass."
    }
}
