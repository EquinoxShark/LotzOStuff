local function get_edition_key(card)
    local edition = card and card.edition
    if not edition then
        return nil
    end

    if edition.key then
        return edition.key
    end

    if edition.type then
        return "e_" .. edition.type
    end

    return nil
end

-- Blank Joker
SMODS.Joker{
    key = "blank_joker",
    atlas = "mod_jokers",
    pos = { x = 1, y = 0 },

    rarity = 1,
    cost = 3,

    loc_txt = {
        name = "Blank Joker",
        text = {
            "Does {C:inactive}nothing{}...?"
        }
    },

    calculate = function(self, card, context)
        if get_edition_key(card) ~= nil then
            card:set_edition(nil, true, true)

            return {
                message = "Cleansed",
                colour = G.C.FILTER
            }
        end

        if not (context.modify_shop_card or context.modify_booster_card) then
            return
        end

        local preview_card = context.card
        if not preview_card then
            return
        end

        local center = preview_card.config and preview_card.config.center
        if not center or center.key ~= "j_loz_anti_joker" then
            return
        end

        if get_edition_key(preview_card) ~= "e_negative" then
            preview_card:set_edition("e_negative", true)
        end
    end
}

-- The Anti-Joker
SMODS.Joker{
    key = "anti_joker",
    atlas = "mod_jokers",
    pos = { x = 0, y = 0 },

    rarity = 3,
    cost = 8,
    eternal_compat = false,

    loc_txt = {
        name = "The Anti-Joker",
        text = {
            "When this card is sold, add {C:dark_edition}Negative{}",
            "to a random joker and {C:red}-1{} hand size"
        }
    },

    in_pool = function(self, args)
        return next(SMODS.find_card("j_loz_blank_joker")) ~= nil
    end,

    add_to_deck = function(self, card, from_debuff)
        if from_debuff then
            return
        end

        if get_edition_key(card) ~= "e_negative" then
            card:set_edition("e_negative", true)
        end
    end,

    calculate = function(self, card, context)
        if not context.selling_self then
            return
        end

        local valid_targets = {}

        if G and G.jokers and G.jokers.cards then
            for _, joker in ipairs(G.jokers.cards) do
                if joker ~= card
                and get_edition_key(joker) == nil then
                    valid_targets[#valid_targets + 1] = joker
                end
            end
        end

        if #valid_targets == 0 then
            return
        end

        local target = pseudorandom_element(valid_targets, pseudoseed("loz_anti_joker"))

        G.E_MANAGER:add_event(Event({
            func = function()
                target:set_edition("e_negative", true)
                target:juice_up()
                G.hand:change_size(-1)
                return true
            end
        }))

        return {
            message = "Negative / -1 Hand",
            colour = G.C.DARK_EDITION
        }
    end
}

-- Solar System
SMODS.Joker{
    key = "solar_system",
    atlas = "mod_jokers",
    pos = { x = 2, y = 0 },

    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt = {
        name = "Solar System",
        text = {
            "Adds the {C:attention}current{} {C:chips}Chips{} and {C:mult}Mult{}",
            "of every {C:attention}other{} poker hand type",
            "contained in the played hand",
            "to this hand's base score"
        }
    },

    calculate = function(self, card, context)
        if not (context.initial_scoring_step and context.main_eval and context.cardarea == G.jokers) then
            return
        end

        local _, _, contained_hands = G.FUNCS.get_poker_hand_info(context.full_hand)

        local chip_add = 0
        local mult_add = 0

        for hand_name, hand_groups in pairs(contained_hands or {}) do
            local hand_data = G.GAME.hands and G.GAME.hands[hand_name]

            if hand_name ~= context.scoring_name
            and hand_data
            and type(hand_groups) == "table"
            and #hand_groups > 0 then
                chip_add = chip_add + (hand_data.chips or 0)
                mult_add = mult_add + (hand_data.mult or 0)
            end
        end

        if chip_add > 0 or mult_add > 0 then
            return {
                chips = chip_add,
                mult = mult_add
            }
        end
    end
}