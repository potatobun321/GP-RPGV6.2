-- world/tiles/wall.lua

return {
    id = "wall",
    name = "Wall", 
    colorKey = "wall", 
    draw_style = "fill", 
    texturePath = "assets/tiles/wall.png",
    flags = {
        solid = true,
        interactable = true,
        interactMessage = "A solid stone wall. It feels cold."
    }
}
