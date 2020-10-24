_addon.name     = 'bp3'
_addon.author   = 'Elidyr'
_addon.version  = '0.20200926'
_addon.command  = 'bp3'

local bp = require('bp/bootstrap')
windower.register_event('addon command', function(...)
    local a = T{...}
    local c = a[1] or false

    if c then
        c = c:lower()

        if bp.commands[c] then
            bp.commands[c].capture(bp, a)

        elseif c == 'test' then
            local target = bp.helpers['target'].changeMode()

            if target then
                table.print(target)
            end

        else
            bp.core.handleCommands(bp, a)

        end

    end

end)

ActionPacket.open_listener(bp.helpers['noknock'].block)
windower.register_event('prerender', function()
    bp.helpers['actions'].setMoving(bp)
    bp.helpers['popchat'].render(bp)
    bp.helpers['debuffs'].render(bp)
    bp.helpers['target'].render(bp)

    if bp.settings['Enabled'] and not bp.allowed[windower.ffxi.get_info().zone] and not bp.shutdown[windower.ffxi.get_info().zone] and (os.clock() - bp.pinger) > bp.settings['Ping Delay'] then
        bp.helpers['queue'].render(bp)
        bp.core.handleAutomation(bp)

        bp.pinger = os.clock()

    elseif bp.settings['Enabled'] and bp.allowed[windower.ffxi.get_info().zone] and not bp.shutdown[windower.ffxi.get_info().zone] and (os.clock() - bp.pinger) > bp.settings['Ping Delay'] then
        bp.helpers['queue'].render(bp)
        bp.core.handleAutomation(bp)

        bp.pinger = os.clock()

    end
    bp.helpers['target'].updateTargets(bp)

end)

windower.register_event('incoming chunk', function(id,original,modified,injected,blocked)

    if id == 0x028 then
        local pack      = bp.packets.parse('incoming', modified)
        local player    = windower.ffxi.get_player()
        local actor     = windower.ffxi.get_mob_by_id(pack['Actor'])
        local target    = windower.ffxi.get_mob_by_id(pack['Target 1 ID'])
        local count     = pack['Target Count']
        local category  = pack['Category']
        local param     = pack['Param']

        --bp.helpers['status'].actions(original)

        if actor and target then

            -- Melee Attacks.
            if pack['Category'] == 1 then

            -- Finish Ranged Attack.
            elseif pack['Category'] == 2 then

                if actor.name == player.name then
                    bp.helpers['actions'].midaction = false
                    bp.helpers['queue'].ready       = (os.clock() + bp.helpers['actions'].getDelays(bp)['Ranged'])

                    -- Remove from action from queue.
                    bp.helpers['queue'].remove(bp, {id=65536,en='Ranged',element=-1,prefix='/ra',type='Ranged', range=14}, actor)

                end

                -- Finish Weaponskill.
            elseif pack['Category'] == 3 then

                if actor.name == player.name then
                    bp.helpers['actions'].midaction = false
                    bp.helpers['queue'].ready       = (os.clock() + bp.helpers['actions'].getDelays(bp)['WeaponSkill'])

                    -- Remove from action from queue.
                    bp.helpers['queue'].remove(bp.res.weapon_skills[param], actor)

                end

                -- Finish Spell Casting.
            elseif pack['Category'] == 4 then

                if actor.name == player.name then
                    local spell  = bp.res.spells[param] or false

                    if spell and type(spell) == 'table' and spell.type then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = (os.clock() + bp.helpers['actions'].getDelays(bp)[spell.type] or 1)

                        -- Remove from action from queue.
                        bp.helpers['queue'].remove(bp, spell, actor)

                        -- Update Cure weights.
                        --bp.helpers['cures'].updateWeight(original)

                    end

                end

            -- Finish using an Item.
            elseif pack['Category'] == 5 then

                if actor.name == player.name then
                    bp.helpers['actions'].midaction = false
                    bp.helpers['queue'].ready       = (os.clock() + bp.helpers['actions'].getDelays(bp)['Item'] or 1)

                    -- Remove from action from queue.
                    bp.helpers['queue'].remove(bp, bp.res.items[param], actor)

                end

            -- Use Job Ability.
            elseif pack['Category'] == 6 then
                local rolls = bp.res.job_abilities:type('CorsairRoll')
                local runes = bp.res.job_abilities:type('Rune')

                if actor.name == player.name then
                    local action = bp.helpers['actions'].buildAction(bp, category, param)
                    local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                    if action then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = (os.clock() + delay)

                        -- Remove from action from queue.
                        bp.helpers['queue'].remove(bp, res.job_abilities[param], actor)

                        --if action and action.type == 'CorsairRoll' then
                            --bp.helpers['rolls'].setRolling(rolls[param].en, pack['Target 1 Action 1 Param'])

                        --elseif runes[param] and bp.helpers['runes'].getBuff(runes[param].en) and bp.helpers['runes'].valid(bp.helpers['runes'].getBuff(runes[param].en).id) then
                            --bp.helpers['runes'].add(bp.helpers['runes'].getBuff(runes[param].en).id)

                        --end

                    end

                elseif actor.name ~= player.name and actor.spawn_type == 16 and bp.res.monster_abilities[param] then

                    if helpers['stunner'].stunnable(bp, param) then
                        helpers['stunner'].stun(bp, param, actor)
                    end

                end

            -- Use Weaponskill.
            elseif pack['Category'] == 7 then

                if actor.name == player.name then
                    local param  = pack['Target 1 Action 1 Param']
                    local action = bp.helpers['actions'].buildAction(bp, category, param)
                    local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                    if param == 24931 then
                        bp.helpers['queue'].ready = (os.clock() + delay)

                    elseif param == 28787 then
                        bp.helpers['queue'].ready = (os.clock() + 1)

                    else
                        bp.helpers['actions'].midaction = false

                    end


                end

            -- Begin Spell Casting.
            elseif pack['Category'] == 8 then

                if actor.name == player.name then

                    if param == 24931 then
                        local param  = pack['Target 1 Action 1 Param']
                        local action = bp.helpers['actions'].buildAction(bp, category, param)
                        local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                        bp.helpers['actions'].midaction = true
                        bp.helpers['queue'].ready       = (os.clock() + delay)

                    elseif param == 28787 then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = (os.clock() + 1)

                    else
                        bp.helpers['actions'].midaction = false

                    end

                end

            -- Begin Item Usage.
            elseif pack['Category'] == 9 then

                -- Make sure that I am using an item.
                if actor.name == player.name then

                    if param == 24931 then
                        local param  = pack['Target 1 Action 1 Param']
                        local action = bp.helpers['actions'].buildAction(bp, category, param)
                        local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                        bp.helpers['actions'].midaction = true
                        bp.helpers['queue'].ready       = (os.clock() + delay)

                    elseif param == 28787 then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = (os.clock() + 1)

                    else
                        bp.helpers['actions'].midaction = false

                    end

                end

            -- NPC TP Move.
            elseif pack['Category'] == 11 then

            -- Begin Ranged Attack.
            elseif pack['Category'] == 12 then

                if actor.name == player.name then
                    local param  = pack['Target 1 Action 1 Param']
                    local action = bp.helpers['actions'].buildAction(bp, category, param)
                    local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                    if param == 24931 then
                        bp.helpers['actions'].midaction = true
                        bp.helpers['queue'].ready       = (os.clock() + delay)

                    elseif param == 28787 then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = (os.clock() + 1)

                    else
                        bp.helpers['actions'].midaction = false

                    end

                end

            -- Finish Pet Ability / Weaponskill.
            elseif pack['Category'] == 13 then

                -- Make sure that I am using the ability.
                if actor.name == player.name then
                    local action = bp.helpers['actions'].buildAction(bp, category, param)
                    local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                    if action then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = (os.clock() + delay)

                        -- Remove from action from queue.
                        bp.helpers['queue'].remove(bp, res.job_abilities[param], actor)

                    end

                end

            -- DNC Abilities
            elseif pack['Category'] == 14 then

                if actor.name == player.name then
                    local action = bp.helpers['actions'].buildAction(bp, category, param)
                    local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                    if action then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = os.clock() + delay

                        -- Remove from action from queue.
                        bp.helpers['queue'].remove(bp, res.job_abilities[param], actor)

                    end

                end

            -- RUN Abilities
            elseif pack['Category'] == 15 then

                if actor.name == player.name then
                    local action = bp.helpers['actions'].buildAction(bp, category, param)
                    local delay  = bp.helpers['actions'].getActionDelay(bp, action) or 1

                    if action then
                        bp.helpers['actions'].midaction = false
                        bp.helpers['queue'].ready       = os.clock() + delay

                        -- Remove from action from queue.
                        bp.helpers['queue'].remove(bp, res.job_abilities[param], actor)

                    end

                end

            end

        end

    end

end)

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)

    if id == 0x00e then
        return bp.helpers['models'].adjustModel(bp, original)
    end

end)