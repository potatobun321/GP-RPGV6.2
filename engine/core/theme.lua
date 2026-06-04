local Theme = {
    current = "dark",
    palettes = {
        dark = {
            bg = {0.1, 0.1, 0.1},
            grass = {0.2, 0.4, 0.2},
            water = {0.2, 0.3, 0.6},
            seawater = {0.1, 0.2, 0.5},
            lava = {0.8, 0.2, 0.0},
            lava2 = {0.9, 0.1, 0.0},
            wall = {0.3, 0.3, 0.3},
            wood = {0.4, 0.2, 0.1},
            sand = {0.8, 0.8, 0.4},
            wildGrass = {0.1, 0.5, 0.1},
            player = {0.9, 0.9, 0.9},
            console_bg = {0, 0, 0, 0.9},
            text = {1, 1, 1}
        },
        light = {
            bg = {0.9, 0.9, 0.9},
            grass = {0.5, 0.8, 0.5},
            water = {0.4, 0.6, 0.9},
            seawater = {0.2, 0.4, 0.8},
            lava = {0.9, 0.3, 0.1},
            lava2 = {1.0, 0.2, 0.1},
            wall = {0.7, 0.7, 0.7},
            wood = {0.6, 0.4, 0.2},
            sand = {0.9, 0.9, 0.6},
            wildGrass = {0.3, 0.7, 0.3},
            player = {0.1, 0.1, 0.1},
            console_bg = {1, 1, 1, 0.9},
            text = {0, 0, 0}
        },
        neon = {
            bg = {0.05, 0.05, 0.1},
            grass = {0.1, 0.0, 0.2},
            water = {0.0, 0.5, 0.5},
            seawater = {0.0, 0.3, 0.5},
            lava = {1.0, 0.0, 0.5},
            lava2 = {1.0, 0.0, 0.8},
            wall = {0.5, 0.0, 0.5},
            wood = {0.8, 0.3, 0.0},
            sand = {1.0, 1.0, 0.0},
            wildGrass = {0.0, 1.0, 0.5},
            player = {0, 1, 1},
            console_bg = {0.05, 0, 0.15, 0.95},
            text = {0, 1, 1}
        },
        dracula = {
            bg = {0.157, 0.165, 0.212},
            grass = {0.314, 0.98, 0.482},
            water = {0.545, 0.914, 0.992},
            seawater = {0.4, 0.7, 0.9},
            lava = {1.0, 0.333, 0.333},
            lava2 = {1.0, 0.2, 0.2},
            wall = {0.267, 0.286, 0.369},
            wood = {0.5, 0.3, 0.2},
            sand = {0.9, 0.9, 0.5},
            wildGrass = {0.2, 0.8, 0.4},
            player = {1, 0.475, 0.776},
            console_bg = {0.157, 0.165, 0.212, 0.95},
            text = {0.973, 0.973, 0.949}
        }
    }
}

function Theme.get()
    return Theme.palettes[Theme.current]
end

function Theme.set(name)
    if Theme.palettes[name] then
        Theme.current = name
        if _G.Event then _G.Event.fire("theme_changed", name) end
        return true
    end
    return false
end

return Theme
