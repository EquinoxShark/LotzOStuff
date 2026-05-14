local function poll_starting_modifier(index, kind)
    local seed_key = "loz_enhanced_" .. kind .. "_" .. index

    if kind == "enh" and SMODS and SMODS.poll_enhancement then
        return SMODS.poll_enhancement({ key = seed_key, guaranteed = true })
    end

    if kind == "seal" and SMODS and SMODS.poll_seal then
        return SMODS.poll_seal({ key = seed_key, guaranteed = true })
    end

    if kind == "edition" then
        if SMODS and SMODS.poll_edition then
            return SMODS.poll_edition({ key = seed_key, guaranteed = true, no_negative = true })
        end
        if poll_edition then
            return poll_edition(seed_key, nil, true, true)
        end
    end
end

local function enhanced_deck_run_active()
    return G
        and G.GAME
        and G.GAME.modifiers
        and G.GAME.modifiers.loz_enhanced_deck
end

local function consumables_locked()
    return G
        and G.GAME
        and G.GAME.blind
        and not G.GAME.blind.in_blind
        and enhanced_deck_run_active()
end

local function is_consumable_card(card)
    if not card then
        return false
    end

    if card.area and G and G.consumeables and card.area == G.consumeables then
        return true
    end

    local card_set = card.config and card.config.center and card.config.center.set
    return (card.ability and card.ability.consumeable)
        or (card_set and SMODS and SMODS.ConsumableTypes and SMODS.ConsumableTypes[card_set])
end

local function ensure_enhanced_deck_consumable_patch()
    if LOZ_ENHANCED_DECK_CONSUMABLE_PATCHED then
        return
    end

    if not Card then
        return
    end

    local patched_any = false

    local function wrap_restricted_method(method_name)
        if not Card[method_name] then
            return false
        end

        local base_method = Card[method_name]
        Card[method_name] = function(self, ...)
            if not base_method(self, ...) then
                return false
            end

            if consumables_locked() and is_consumable_card(self) then
                return false
            end

            return true
        end

        return true
    end

    patched_any = wrap_restricted_method("can_use_consumeable") or patched_any
    patched_any = wrap_restricted_method("can_sell_card") or patched_any

    if patched_any then
        LOZ_ENHANCED_DECK_CONSUMABLE_PATCHED = true
    end
end

SMODS.Back{
    key = "expanding_deck",
    atlas = "mod_decks",
    pos = { x = 0, y = 0 },

    loc_txt = {
        name = "Expanding Deck",
        text = {
            "Start with {C:attention}104{} cards",
            "Gain {C:blue}+1{} hand size",
            "after each defeated blind"
        }
    },

    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                local original_size = #G.playing_cards

                for i = original_size, 1, -1 do
                    G.playing_card = #G.playing_cards + 1
                    local copied = copy_card(G.playing_cards[i], nil, 1, G.playing_card)
                    copied:add_to_deck()

                    G.deck.config.card_limit = G.deck.config.card_limit + 1
                    G.deck:emplace(copied)
                    G.playing_cards[#G.playing_cards + 1] = copied
                end

                return true
            end
        }))
    end,

    calculate = function(self, back, context)
        if context.end_of_round and context.main_eval and not context.game_over then
            G.hand:change_size(1)
            return {
                message = "+1 Hand Size",
                colour = G.C.BLUE
            }
        end
    end
}

SMODS.Back{
    key = "enhanced_deck",
    atlas = "mod_decks",
    pos = { x = 1, y = 0 },

    loc_txt = {
        name = "Enhanced Deck",
        text = {
            "All starting cards gain random",
            "{C:attention}Enhancement{}, {C:attention}Seal{}, and {C:attention}Edition{}",
            "Cannot use or sell consumables",
            "outside of an active blind"
        }
    },

    apply = function(self, back)
        ensure_enhanced_deck_consumable_patch()

        G.E_MANAGER:add_event(Event({
            func = function()
                if not (G and G.GAME and G.GAME.modifiers) then
                    return true
                end

                G.GAME.modifiers.loz_enhanced_deck = true

                if not G.playing_cards then
                    return true
                end

                local centers = G.P_CENTERS

                for i = 1, #G.playing_cards do
                    local playing_card = G.playing_cards[i]
                    local enhancement_key = poll_starting_modifier(i, "enh")
                    local seal_key = poll_starting_modifier(i, "seal")
                    local edition_key = poll_starting_modifier(i, "edition")

                    if playing_card and enhancement_key and centers and centers[enhancement_key] then
                        playing_card:set_ability(centers[enhancement_key], nil, true)
                    end

                    if playing_card and seal_key then
                        playing_card:set_seal(seal_key, true, true)
                    end

                    if playing_card and edition_key then
                        playing_card:set_edition(edition_key, true)
                    end
                end

                return true
            end
        }))
    end
}