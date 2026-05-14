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
        if not LOZ_ENHANCED_DECK_CONSUMABLE_PATCHED and Card then
            local function wrap_restricted_method(method_name)
                if not Card[method_name] then
                    return false
                end

                local base_method = Card[method_name]
                Card[method_name] = function(card, ...)
                    if not base_method(card, ...) then
                        return false
                    end

                    local consumeable_set = card.config and card.config.center and card.config.center.set
                    local is_consumable =
                        (card.area and G and G.consumeables and card.area == G.consumeables)
                        or (card.ability and card.ability.consumeable)
                        or (consumeable_set and SMODS.ConsumableTypes[consumeable_set])

                    if G
                        and G.GAME
                        and G.GAME.blind
                        and not G.GAME.blind.in_blind
                        and G.GAME.modifiers
                        and G.GAME.modifiers.loz_enhanced_deck
                        and is_consumable
                    then
                        return false
                    end

                    return true
                end

                return true
            end

            local use_wrapped = wrap_restricted_method("can_use_consumeable")
            local sell_wrapped = wrap_restricted_method("can_sell_card")

            if use_wrapped or sell_wrapped then
                LOZ_ENHANCED_DECK_CONSUMABLE_PATCHED = true
            end
        end

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
                    local enhancement_key = SMODS.poll_enhancement({
                        key = "loz_enhanced_enh_" .. i,
                        guaranteed = true
                    })
                    local seal_key = SMODS.poll_seal({
                        key = "loz_enhanced_seal_" .. i,
                        guaranteed = true
                    })
                    local edition_key = SMODS.poll_edition({
                        key = "loz_enhanced_edition_" .. i,
                        guaranteed = true,
                        no_negative = true
                    })

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