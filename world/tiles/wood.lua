-- world/tiles/wood.lua

return {
    id = "wood",
    name = "Wood", 
    colorKey = "wood", 
    draw_style = "fill", 
    texturePath = "assets/tiles/wood.png",
    flags = {
        solid = true,
        interactable = true,
        interactMessage = "A solid wooden wall."
    }
}
