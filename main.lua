SMODS.Atlas{
    key = "mod_jokers",
    path = "jokers.png",
    px = 71,
    py = 95
}

SMODS.Atlas{
    key = "mod_decks",
    path = "decks.png",
    px = 71,
    py = 95
}


assert(SMODS.load_file("decks.lua"))()
assert(SMODS.load_file("jokers.lua"))()