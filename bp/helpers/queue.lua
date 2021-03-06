local queue = {}
local files = require('files')
local texts = require('texts')
local res   = require('resources')
local f     = files.new('bp/helpers/settings/queue_settings.lua')
require('queues')

if not f:exists() then
    f:write(string.format('return %s', T({}):tovstring()))
end

function queue.new()
    local self = {}

    -- Static Variables.
    self.settings   = dofile(string.format('%sbp/helpers/settings/queue_settings.lua', windower.addon_path))
    self.layout     = self.settings.layout or {pos={x=500, y=75}, colors={text={alpha=255, r=245, g=200, b=20}, bg={alpha=200, r=0, g=0, b=0}, stroke={alpha=255, r=0, g=0, b=0}}, font={name='Lucida Console', size=8}, padding=5, stroke_width=1, draggable=false}
    self.display    = texts.new('', {flags={draggable=self.layout.draggable}})
    self.important  = string.format('%s,%s,%s', 25, 165, 200)

    -- Public Variables.
    self.queue      = Q{}
    self.ready      = 0
    self.max        = self.settings.max or 20

    -- Private Variables.
    local protection    = os.clock()
    local loaded        = false

    -- Private Functions.
    local persist = function()
        local next = next

        if self.settings then
            self.settings.max       = self.max
            self.settings.layout    = self.layout

        end

    end
    persist()

    local resetDisplay = function()
        self.display:pos(self.layout.pos.x, self.layout.pos.y)
        self.display:font(self.layout.font.name)
        self.display:color(self.layout.colors.text.r, self.layout.colors.text.g, self.layout.colors.text.b)
        self.display:alpha(self.layout.colors.text.alpha)
        self.display:size(self.layout.font.size)
        self.display:pad(self.layout.padding)
        self.display:bg_color(self.layout.colors.bg.r, self.layout.colors.bg.g, self.layout.colors.bg.b)
        self.display:bg_alpha(self.layout.colors.bg.alpha)
        self.display:stroke_width(self.layout.stroke_width)
        self.display:stroke_color(self.layout.colors.stroke.r, self.layout.colors.stroke.g, self.layout.colors.stroke.b)
        self.display:stroke_alpha(self.layout.colors.stroke.alpha)
        self.display:update()

    end
    resetDisplay()

    -- Static Functions.
    self.writeSettings = function()

        if f:exists() then
            f:write(string.format('return %s', T(self.settings):tovstring()))

        elseif not f:exists() then
            f:write(string.format('return %s', T({}):tovstring()))
        end

    end
    self.writeSettings()

    self.attempt = function()

        if self.queue and self.queue[1] and self.queue[1].attempts then
            self.queue[1].attempts, protection = (self.queue[1].attempts + 1), os.clock()
            return self.queue[1].attempts

        else
            self.clear()

        end

    end

    self.clear = function()
        self.queue:clear()
        self.queue = Q{}
        self.display:text('')
        self.display:update()
        self.display:hide()

    end

    self.zoneChange = function()
        self.clear()
        self.writeSettings()
        self.display:text('')
        self.display:update()
        self.display:hide()

    end

    -- Public Functions.
    self.checkReady = function(bp)
        local player      = windower.ffxi.get_player() or false
        local ready       = {[0]=0,[1]=1}

        if (os.clock()-self.ready) > 0 and player and ready[player.status] then

            if not loaded then
                bp.helpers['equipment'].update()
            end
            return true

        end
        return false

    end

    self.render = function(bp)
        local bp        = bp or false
        local contents  = {}
        local text      = ((' '):lpad(' ', 20) .. ('[ ACTION QUEUE ]') .. (' '):rpad(' ', 20))

        if self.queue:length() == 0 and self.display:visible() == true then
            self.display:text('')
            self.display:hide()

        elseif self.queue:length() > 0 then
            local update = {}

            for i,v in ipairs(self.queue.data) do

                if i < self.max + 1 then

                    if v.action and v.target and v.priority then
                        local colors    = {name='0,153,204', attempts='255,255,255', target='102,225,051', cost='50,180,120'}
                        local name      = (v.action.en):sub(1,20) or ('NONE')
                        local attempts  = (v.attempts)
                        local target    = (v.target.name):sub(1,15) or ('NONE')
                        local cost      = v.action.mp_cost or ('0')
                        local ready     = (self.ready-os.clock()) > 0 and (self.ready-os.clock()) or 0

                        -- Add string to update table.
                        if i == 1 then
                            table.insert(update, string.format((' %s **[ ACTION QUEUE: (\\cs(%s)%2.2f\\cr) ]** %s\n<\\cs(%s)%02d\\cr>%s[ \\cs(%s)%s\\cr ]%s\\cs(%s)%s\\cr%s►%s\\cs(%s)%s\\cr'),
                                (''):lpad(' ', 20), self.important, ready, (''):rpad(' ', 20),
                                (colors.attempts),
                                (attempts),
                                (' '):rpad(' ', 2-tostring(attempts):len()),
                                (colors.cost),
                                (string.format('%03d', cost)),
                                (' '):rpad(' ', 2-tostring(cost):len()),
                                (colors.name),
                                (name),
                                (''):rpad('-', 25-name:len()),
                                (''):rpad(' ', 2),
                                (colors.target),
                                (target)
                            ))

                        else
                            table.insert(update, string.format(('<\\cs(%s)%02d\\cr>%s[ \\cs(%s)%s\\cr ]%s\\cs(%s)%s\\cr%s►%s\\cs(%s)%s\\cr'),
                                (colors.attempts),
                                (attempts),
                                (' '):rpad(' ', 2-tostring(attempts):len()),
                                (colors.cost),
                                (string.format('%03d', cost)),
                                (' '):rpad(' ', -tostring(cost):len()),
                                (colors.name),
                                (name),
                                (''):rpad(' ', 25-name:len()),
                                (''):rpad(' ', 2),
                                (colors.target),
                                (target)
                            ))

                        end

                    end

                end

            end

            self.display:text(table.concat(update, '\n'))
            self.display:bg_visible(true)
            self.display:bg_alpha(self.layout.colors.bg.alpha)
            self.display:update()
            self.display:show()

        end

    end

    self.addToFront = function(bp, action, target)
        local bp            = bp or false
        local player        = windower.ffxi.get_player() or false
        local me            = windower.ffxi.get_mob_by_target('me') or false
        local levels        = {main=player.main_job_level, sub=player.sub_job_level}
        local helpers       = bp.helpers or false
        local target        = target or false
        local priority      = 0
        local required

        if bp and helpers then
            local action_type  = self.getType(bp, action)
            
            if (player.status == 0 or player.status == 1) and not helpers['actions'].moving then

                if type(target) == 'string' then
                    local types = T{'t','bt','st','me','ft','ht','pet'}

                    if types:contains(target) and windower.ffxi.get_mob_by_target(target) then
                        target = windower.ffxi.get_mob_by_target(target)

                    elseif windower.ffxi.get_mob_by_name(target) then
                        target = windower.ffxi.get_mob_by_name(target)

                    end

                elseif type(target) == 'number' then

                    if windower.ffxi.get_mob_by_id(target) then
                        target = windower.ffxi.get_mob_by_id(target)
                    end

                elseif type(target) == 'table' then

                    if target.id then

                        if windower.ffxi.get_mob_by_id(target.id) then
                            target = windower.ffxi.get_mob_by_id(target.id)
                        end

                    end

                end

                if action and action.levels then
                    required = {main=(action.levels[player.main_job_id] or 255), sub=(action.levels[player.sub_job_id] or 255)}

                    if levels.main == 99 then
                        levels.main = 100
                    end

                else
                    required = {main=0, sub=0}
                end

                if target and me then
                    local ranges        = helpers['actions'].getRanges(bp)
                    local distance      = (target.distance):sqrt()
                    local bypass_type   = T{'Rune'}
                    
                    if helpers['target'].onlySelf(bp, action) and target.id ~= player.id and not helpers['buffs'].buffActive(584) and not self.inQueue(bp, bp.JA['Entrust']) then
                        target = windower.ffxi.get_mob_by_target('me')
                    end
                    
                    if action_type == 'JobAbility' and helpers['actions'].canAct(bp) and (not self.inQueue(bp, action, target) or bypass_type:contains(action.type)) then

                        if helpers['actions'].isReady(bp, 'JA', action.en) then

                            if action.prefix == '/pet' then
                                local pet       = windower.ffxi.get_mob_by_target('pet') or false
                                local distance  = ( (target.x-pet.x)^2 + (target.y-pet.y)^2 ):sqrt()

                                if pet and distance < (ranges[action.range]+target.model_size+pet.model_size) and (target.distance):sqrt() < 21 and not self.inQueue(bp, action) and player['vitals'].mp >= action.mp_cost then
                                    self.queue:push({action=action, target=target, priority=priority, attempts=1})
                                end

                            else

                                if distance < (ranges[action.range]+target.model_size) and player['vitals'].mp >= action.mp_cost then
                                    self.queue:push({action=action, target=target, priority=priority, attempts=1})
                                end

                            end

                        end

                    elseif action_type == 'Magic' and (levels.main >= required.main or levels.sub >= required.sub) and helpers['actions'].canCast(bp) then
                        
                        if (helpers['actions'].isReady(bp, 'MA', action.en) or action.prefix == '/song') and player['vitals'].mp > action.mp_cost then

                            if distance < ((ranges[action.range]+target.model_size) + 2) then
                                
                                if action.prefix == '/song' and helpers['party'].isInParty(bp, target.id, false) then
                                    
                                    if helpers['actions'].isReady(bp, 'JA', 'Pianissimo') and helpers['songs'].piano then
                                        self.queue:insert(1, {action=bp.JA['Pianissimo'], target=me, priority=priority, attempts=1})
                                        self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})

                                    else
                                        self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})

                                    end

                                elseif action.type == 'Geomancy' and not self.inQueue(bp, action) and (action.en):match('Geo-') and T(action.targets):contains('Party') and player['vitals'].mp >= action.mp_cost then
                                    
                                    if helpers['party'].isInParty(bp, target.id, false) then
                                        self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})

                                    else
                                        self.queue:insert(1, {action=action, target=player, priority=priority, attempts=1})

                                    end

                                elseif action.type == 'Geomancy' and not self.inQueue(bp, action) and (action.en):match('Geo-') and T(action.targets):contains('Enemy') and helpers['target'].isEnemy(bp, target) and player['vitals'].mp >= action.mp_cost then
                                    self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})

                                elseif not self.inQueue(bp, action, target) and not (action.en):match('Geo-') and player['vitals'].mp >= action.mp_cost then

                                    if action.type == 'SummonerPact' then

                                        if not self.typeInQueue(bp, action) then
                                            self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})
                                        end
                                    
                                    else
                                        self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})

                                    end

                                end

                            end

                        end

                    elseif action_type == 'WeaponSkill' then

                        if helpers['actions'].canAct(bp) and not self.inQueue(bp, action, target) and helpers['actions'].isReady(bp, 'WS', action.en) and player['vitals'].tp > 1000 then

                            if distance < (ranges[action.range]+target.model_size) then
                                self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})
                            end

                        end

                    elseif action_type == 'Item' then

                        if helpers['actions'].canItem(bp) and not self.inQueue(action, target) then
                            local allowed = {0,8,10,11,12}

                            for _,v in ipairs(allowed) do

                                if (helpers['inventory'].findItemByName(action.en, v)) then
                                    self.queue:insert(1, {action=action, target=target, priority=priority, attempts=1})
                                end

                            end

                        end

                    elseif action_type == 'Ranged' then
                        helpers['equipment'].update()
                        
                        if helpers['actions'].canAct(bp) and not self.inQueue(bp, helpers['actions'].unique.ranged, target) then

                            if helpers['equipment'].ranged and helpers['equipment'].ranged.en ~= 'Gil' and helpers['equipment'].ammo and helpers['equipment'].ammo.en ~= 'Gil' then
                                helpers['actions'].unique.ranged.en = helpers['equipment'].ranged.en
                            
                                if distance < (ranges[action.range]+target.model_size) then
                                    self.queue:insert(1, {action=helpers['actions'].unique.ranged, target=target, priority=priority, attempts=1})
                                end

                            elseif helpers['equipment'].ranged and helpers['equipment'].ranged.en == 'Gil' and helpers['equipment'].ammo and helpers['equipment'].ammo.en ~= 'Gil' then
                                helpers['actions'].unique.ranged.en = helpers['equipment'].ammo.en
                            
                                if distance < (ranges[action.range]+target.model_size) then
                                    self.queue:insert(1, {action=helpers['actions'].unique.ranged, target=target, priority=priority, attempts=1})
                                end

                            end

                        end

                    end

                end

            end

        end

    end

    self.add = function(bp, action, target)
        local bp            = bp or false
        local player        = windower.ffxi.get_player() or false
        local me            = windower.ffxi.get_mob_by_target('me') or false
        local levels        = {main=player.main_job_level, sub=player.sub_job_level}
        local helpers       = bp.helpers or false
        local target        = target or false
        local priority      = 0
        local required

        if bp and helpers then
            local action_type  = self.getType(bp, action)
            
            if (player.status == 0 or player.status == 1) and not helpers['actions'].moving then

                if type(target) == 'string' then
                    local types = T{'t','bt','st','me','ft','ht'}

                    if types:contains(target) and windower.ffxi.get_mob_by_target(target) then
                        target = windower.ffxi.get_mob_by_target(target)

                    elseif windower.ffxi.get_mob_by_name(target) then
                        target = windower.ffxi.get_mob_by_name(target)

                    end

                elseif type(target) == 'number' then

                    if windower.ffxi.get_mob_by_id(target) then
                        target = windower.ffxi.get_mob_by_id(target)
                    end

                elseif type(target) == 'table' then

                    if target.id then

                        if windower.ffxi.get_mob_by_id(target.id) then
                            target = windower.ffxi.get_mob_by_id(target.id)
                        end

                    end

                end

                if action and action.levels then
                    required = {main=(action.levels[player.main_job_id] or 255), sub=(action.levels[player.sub_job_id] or 255)}

                    if levels.main == 99 then
                        levels.main = 100
                    end

                else
                    required = {main=0, sub=0}
                end
                
                if target and me then
                    local ranges        = helpers['actions'].getRanges(bp)
                    local distance      = (target.distance):sqrt()
                    local bypass_type   = T{'Rune'}
                    
                    if helpers['target'].onlySelf(bp, action) and target.id ~= player.id and not helpers['buffs'].buffActive(584) and not self.inQueue(bp, bp.JA['Entrust']) then
                        target = windower.ffxi.get_mob_by_target('me')                        
                    end
                    
                    if action_type == 'JobAbility' and helpers['actions'].canAct(bp) and (not self.inQueue(bp, action, target) or bypass_type:contains(action.type)) then

                        if helpers['actions'].isReady(bp, 'JA', action.en) then

                            if action.prefix == '/pet' then
                                local pet = windower.ffxi.get_mob_by_target('pet') or false
                                local distance  = ( (target.x-pet.x)^2 + (target.y-pet.y)^2 ):sqrt()
                                
                                if pet and distance < (ranges[action.range]+target.model_size+pet.model_size) and (target.distance):sqrt() < 21 and not self.inQueue(bp, action) and player['vitals'].mp >= action.mp_cost then
                                    self.queue:push({action=action, target=target, priority=priority, attempts=1})
                                end

                            else

                                if distance < (ranges[action.range]+target.model_size) and player['vitals'].mp >= action.mp_cost then
                                    self.queue:push({action=action, target=target, priority=priority, attempts=1})
                                end

                            end

                        end

                    elseif action_type == 'Magic' and (levels.main >= required.main or levels.sub >= required.sub) and helpers['actions'].canCast(bp) and not self.inQueue(bp, action, target) then
                        
                        if (helpers['actions'].isReady(bp, 'MA', action.en) or action.prefix == '/song') and player['vitals'].mp > action.mp_cost then

                            if distance < ((ranges[action.range]+target.model_size) + 2) then

                                if action.prefix == '/song' and helpers['party'].isInParty(bp, target.id, false) then
                                    
                                    if helpers['actions'].isReady(bp, 'JA', 'Pianissimo') and helpers['songs'].piano then
                                        self.queue:push({action=bp.JA['Pianissimo'], target=me, priority=priority, attempts=1})
                                        self.queue:push({action=action, target=target, priority=priority, attempts=1})

                                    else
                                        self.queue:push({action=action, target=target, priority=priority, attempts=1})

                                    end

                                elseif action.type == 'Geomancy' and (action.en):match('Geo-') and T(action.targets):contains('Self') and target.id == player.id and player['vitals'].mp >= action.mp_cost then
                                    self.queue:push({action=action, target=target, priority=priority, attempts=1})

                                elseif action.type == 'Geomancy' and (action.en):match('Geo-') and T(action.targets):contains('Enemy') and helpers['target'].isEnemy(bp, target) and player['vitals'].mp >= action.mp_cost then
                                    self.queue:push({action=action, target=target, priority=priority, attempts=1})

                                elseif not self.inQueue(bp, action, target) and not (action.en):match('Geo-') and player['vitals'].mp >= action.mp_cost then

                                    if action.type == 'SummonerPact' then

                                        if not self.typeInQueue(bp, action) then
                                            self.queue:push({action=action, target=target, priority=priority, attempts=1})
                                        end
                                    
                                    else
                                        self.queue:push({action=action, target=target, priority=priority, attempts=1})

                                    end

                                end

                            end

                        end

                    elseif action_type == 'WeaponSkill' then

                        if helpers['actions'].canAct(bp) and not self.inQueue(bp, action, target) and helpers['actions'].isReady(bp, 'WS', action.en) and player['vitals'].tp > 1000 then

                            if distance < (ranges[action.range]+target.model_size) then
                                self.queue:push({action=action, target=target, priority=priority, attempts=1})
                            end

                        end

                    elseif action_type == 'Item' then

                        if helpers['actions'].canItem(bp) and not self.inQueue(action, target) then
                            local allowed = {0,8,10,11,12}

                            for _,v in ipairs(allowed) do

                                if (helpers['inventory'].findItemByName(action.en, v)) then
                                    self.queue:push({action=action, target=target, priority=priority, attempts=1})
                                end

                            end

                        end

                    elseif action_type == 'Ranged' then
                        helpers['equipment'].update()
                        
                        if helpers['actions'].canAct(bp) and not self.inQueue(bp, helpers['actions'].unique.ranged, target) then

                            if helpers['equipment'].ranged and helpers['equipment'].ranged.en ~= 'Gil' and helpers['equipment'].ammo and helpers['equipment'].ammo.en ~= 'Gil' then
                                helpers['actions'].unique.ranged.en = helpers['equipment'].ranged.en
                            
                                if distance < (ranges[action.range]+target.model_size) then
                                    self.queue:push({action=helpers['actions'].unique.ranged, target=target, priority=priority, attempts=1})
                                end

                            elseif helpers['equipment'].ranged and helpers['equipment'].ranged.en == 'Gil' and helpers['equipment'].ammo and helpers['equipment'].ammo.en ~= 'Gil' then
                                helpers['actions'].unique.ranged.en = helpers['equipment'].ammo.en
                            
                                if distance < (ranges[action.range]+target.model_size) then
                                    self.queue:push({action=helpers['actions'].unique.ranged, target=target, priority=priority, attempts=1})
                                end

                            end

                        end

                    end

                end

            end

        end

    end

    self.handle = function(bp)
        local bp = bp or false

        if bp and self.queue and self.queue:length() > 0 and (os.clock()-protection) > 1 and self.checkReady(bp) then
            local player    = windower.ffxi.get_player() or false
            local helpers   = bp.helpers
            local action    = self.queue[1].action
            local target    = self.queue[1].target
            local priority  = self.queue[1].priority
            local attempts  = self.queue[1].attempts
            local type      = self.getType(bp, action)
            local special   = T{'Raise','Raise II','Raise III','Arise'}
            local ranges    = helpers['actions'].getRanges(bp)

            if player and action and target and priority and attempts and type and ranges then

                if type == 'JobAbility' then

                    if helpers['target'].allowed(bp, target) then
                        local mob      = windower.ffxi.get_mob_by_id(target.id)
                        local distance = mob.distance:sqrt()

                        if attempts == 15 then
                            helpers['queue'].remove(bp, res.job_abilities[action.id], target)

                        elseif not helpers['actions'].canAct(bp) or not helpers['actions'].isReady(bp, 'JA', action.en) and action.en ~= 'Pianissimo' and action.type ~= 'Rune' then
                            helpers['queue'].remove(bp, res.job_abilities[action.id], target)

                        elseif action.prefix == '/pet' then
                            local pet = windower.ffxi.get_mob_by_target('pet') or false

                            if pet and (action.type == 'BloodPactRage' or action.type == 'BloodPactWard') then
                                local distance = ( (target.x-pet.x)^2 + (target.y-pet.y)^2 ):sqrt()

                                if distance < (ranges[action.range]+target.model_size+pet.model_size) and (mob.distance):sqrt() < 21 then
                                    windower.send_command(string.format("input %s '%s' %s", action.prefix, action.en, target.id))
                                    helpers['queue'].attempt(bp)
                                    helpers['coms'].send(bp, action, player.name, attempts)

                                elseif distance > (ranges[action.range]+target.model_size+pet.model_size) or (mob.distance):sqrt() > 21 then
                                    helpers['queue'].remove(bp, res.job_abilities[action.id], target)

                                end

                            elseif pet then
                                local distance = ( (target.x-pet.x)^2 + (target.y-pet.y)^2 ):sqrt()

                                if pet and distance < (ranges[action.range]+target.model_size+pet.model_size) and (mob.distance):sqrt() < 21 then
                                    windower.send_command(string.format("input %s '%s' %s", action.prefix, action.en, target.id))
                                    helpers['queue'].attempt(bp)
                                    helpers['coms'].send(bp, action, player.name, attempts)

                                elseif pet and distance > (ranges[action.range]+target.model_size+pet.model_size) or (mob.distance):sqrt() > 21 then
                                    helpers['queue'].remove(bp, res.job_abilities[action.id], target)

                                elseif not pet then
                                    helpers['queue'].remove(bp, res.job_abilities[action.id], target)

                                end

                            elseif not pet then
                                helpers['queue'].remove(bp, res.job_abilities[action.id], target)

                            end

                        else

                            if distance < (ranges[action.range]+target.model_size) and action.type ~= 'Rune' then
                                windower.send_command(string.format("input %s '%s' %s", action.prefix, action.en, target.id))
                                helpers['queue'].attempt(bp)
                                helpers['coms'].send(bp, action, player.name, attempts)

                            elseif distance < (ranges[action.range]+target.model_size) and action.type == 'Rune' then

                                if helpers['actions'].isReady(bp, 'JA', action.en) then
                                    windower.send_command(string.format("input %s '%s' %s", action.prefix, action.en, target.id))
                                    helpers['queue'].attempt(bp)
                                    helpers['coms'].send(bp, action, player.name, attempts)
                                
                                else
                                    helpers['queue'].attempt(bp)
                                    helpers['coms'].send(bp, action, player.name, attempts)

                                end

                            elseif distance > (ranges[action.range]+target.model_size) then
                                helpers['queue'].remove(bp, res.job_abilities[action.id], target)

                            end

                        end

                    elseif not helpers['target'].allowed(bp, target) then
                        helpers['queue'].remove(bp, action, target)

                    end

                elseif type == 'Magic' then
                    
                    if (helpers['target'].allowed(bp, target) or special:contains(action.en)) then
                        local mob       = windower.ffxi.get_mob_by_id(target.id) or 999
                        local pet       = windower.ffxi.get_mob_by_target('pet') or false
                        local distance  = mob.distance:sqrt()
                        local size      = target.model_size or 1

                        if attempts == 15 then
                            helpers['queue'].remove(bp, res.spells[action.id], target)

                        elseif action.prefix ~= '/song' and (not helpers['actions'].canCast() or not helpers['actions'].isReady(bp, 'MA', action.en) or player['vitals'].mp < action.mp_cost) then
                            helpers['queue'].remove(bp, res.spells[action.id], target)

                        --elseif action.prefix == '/song' and self.queue[1].attempts == 3 and (not helpers['actions'].canCast() or not helpers['actions'].isReady(bp, 'MA', action.en)) then
                        elseif action.prefix == '/song' and not helpers['actions'].canCast() or not helpers['actions'].isReady(bp, 'MA', action.en) then
                            helpers['queue'].attempt(bp)
                            --helpers['queue'].remove(bp, res.spells[action.id], target)

                        elseif distance < (ranges[action.range]+size) then

                            if T{'Carbuncle','Ifrit','Ramuh','Shiva','Garuda','Cait Sith','Leviathan','Titan','Siren','Atomos','Odin','Alexander','Fenrir','Diabolos'}:contains(action.en) and pet then
                                helpers['queue'].remove(bp, res.spells[action.id], target)
                            
                            else
                                bp.helpers['actions'].locked = {flag=true, x=windower.ffxi.get_mob_by_target('me').x, y=windower.ffxi.get_mob_by_target('me').y, z=windower.ffxi.get_mob_by_target('me').z}
                                windower.send_command(string.format("input %s '%s' %s", action.prefix, action.en, target.id))
                                helpers['queue'].attempt(bp)
                                helpers['coms'].send(bp, action, player.name, attempts)

                            end

                        elseif distance > (ranges[action.range]+size) then
                            helpers['queue'].remove(bp, res.spells[action.id], target)

                        end

                    elseif not helpers['target'].allowed(bp, target) then
                        helpers['queue'].remove(bp, action, target)

                    end

                elseif type == 'WeaponSkill' then

                    if helpers['target'].allowed(bp, target) then
                        local mob      = windower.ffxi.get_mob_by_id(target.id)
                        local distance = mob.distance:sqrt()

                        if attempts == 15 then
                            helpers['queue'].remove(bp, res.weapon_skills[action.id], target)

                        elseif not helpers['actions'].canAct(bp) or not helpers['actions'].isReady(bp, 'WS', action.en) or player['vitals'].tp < 1000 then
                            helpers['queue'].remove(bp, res.weapon_skills[action.id], target)

                        elseif distance < (ranges[action.range]+target.model_size) then
                            windower.send_command(string.format("input %s '%s' %s", action.prefix, action.en, target.id))
                            helpers['queue'].attempt(bp)
                            helpers['coms'].send(bp, action, player.name, attempts)

                        elseif distance > (ranges[action.range]+target.model_size) then
                            helpers['queue'].remove(bp, res.weapon_skills[action.id], target)

                        end

                    elseif not helpers['target'].allowed(bp, target) then
                        helpers['queue'].remove(bp, action, target)

                    end

                elseif type == 'Item' then

                    if helpers['target'].allowed(bp, target) then
                        local mob      = windower.ffxi.get_mob_by_id(target.id)
                        local distance = mob.distance:sqrt()

                        if attempts == 15 then
                            helpers['queue'].remove(bp, res.items[action.id], target)

                        elseif not helpers['actions'].canItem(bp) or helpers['buffs'].buffActive(473) then
                            helpers['queue'].remove(bp, res.items[action.id], target)

                        else
                            windower.send_command(string.format('input /item "%s" <me>', action.en))
                            helpers['queue'].attempt(bp)
                            helpers['coms'].send(bp, action, player.name, attempts)

                        end

                    elseif not helpers['target'].allowed(bp, target) then
                        helpers['queue'].remove(bp, action, target)

                    end

                elseif type == 'Ranged' then
                    helpers['equipment'].update()

                    if helpers['actions'].canAct(bp) and helpers['target'].allowed(bp, target) then
                        local mob      = windower.ffxi.get_mob_by_id(target.id)
                        local distance = mob.distance:sqrt()
                        
                        if (attempts == 15 or not helpers['equipment'].ammo) or helpers['equipment'].ammo and helpers['equipment'].ammo.en == 'Gil' then
                            helpers['queue'].remove(bp, helpers['actions'].unique.ranged, target)

                        elseif distance < (ranges[action.range]+target.model_size) then
                            windower.send_command(string.format("input %s %s", action.prefix, target.id))
                            helpers['queue'].attempt(bp)
                            helpers['coms'].send(bp, action, player.name, attempts)
                            helpers['equipment'].update()

                        elseif distance > (ranges[action.range]+target.model_size) then
                            helpers['queue'].remove(bp, helpers['actions'].unique.ranged, target)

                        end

                    elseif not helpers['target'].allowed(bp, target) then
                        helpers['queue'].remove(bp, action, target)

                    end

                end

            end

        end

    end

    self.getType = function(bp, action)
        local helpers = bp.helpers or false

        if helpers then
            local action_type    = helpers['actions'].getActionType(bp, action)
            local spell_types    = T{'BlackMagic','WhiteMagic','BlueMagic','SummonerPact','Ninjutsu','BardSong','Geomancy','Trust'}
            local ability_types  = T{'JobAbility','PetCommand','CorsairRoll','CorsairShot','Samba','Waltz','Jig','Step','Flourish1','Flourish2','Flourish3','Scholar','Rune','Ward','Effusion','BloodPactWard','BloodPactRage','Monster'}
            local wskill_types   = 'WeaponSkill'
            local item_type      = 'Item'
            local ranged_type    = 'Ranged'
            local movement       = 'Movement'

            if ability_types:contains(action_type) then
                return 'JobAbility'

            elseif spell_types:contains(action_type) then
                return 'Magic'

            elseif action_type == wskill_types then
                return 'WeaponSkill'

            elseif action_type == item_type then
                return 'Item'

            elseif action_type == ranged_type then
                return 'Ranged'

            elseif action_type == movement then
                return 'Movement'

            end
            return false

        end

    end

    self.remove = function(bp, action, target)
        local bp        = bp or false
        local action    = action or false
        local target    = target or false
        local cures     = T{1,2,3,4,5,6,7,8,9,10,11,549,645,578,593,711,581,690}
        local waltz     = T{190,191,192,193,311,195,262}

        if action and target then

            for i,v in ipairs(self.queue.data) do

                if type(v) == 'table' and type(target) == 'table' and v.action then

                    if (cures):contains(action.id) and (cures):contains(v.action.id) and action.prefix == '/magic' then
                        self.queue:remove(i)
                        break

                    elseif (waltz):contains(action.id) and (waltz):contains(v.action.id) and action.prefix == '/jobability' then
                        self.queue:remove(i)
                        break

                    elseif v.action.id == action.id and action.en ~= 'Pianissimo' then

                        if v.action.type == 'Weapon' then
                            self.queue:remove(i)
                            break

                        elseif v.action.type == action.type and v.action.en == action.en then
                            self.queue:remove(i)
                            break

                        end

                    elseif action.en == 'Pianissimo' then
                        self.queue:remove(i)
                        break

                    end

                end

            end
            bp.helpers['actions'].locked.flag = false

        end

    end

    self.inQueue = function(bp, action, target)
        local bp        = bp or false
        local action    = action or false
        local target    = target or false

        if action and target and self.queue.data then

            for _,v in ipairs(self.queue.data) do

                if type(v) == 'table' and type(action) == 'table' and type(target) == 'table' and v.action and v.target then

                    if v.action.id == action.id and v.action.type == action.type and v.action.en == action.en and v.target.id == target.id then
                        return true
                    end

                end

            end

        elseif action and not target and self.queue.data then

            for _,v in ipairs(self.queue.data) do

                if type(v) == 'table' and type(action) == 'table' and v.action then

                    if v.action.id == action.id and v.action.type == action.type and v.action.en == action.en then
                        return true
                    end

                end

            end

        end
        return false

    end

    self.typeInQueue = function(bp, action)
        local bp        = bp or false
        local action    = action or false

        if action and self.queue.data then

            for _,v in ipairs(self.queue.data) do

                if type(v) == 'table' and type(action) == 'table' and v.action then

                    if v.action.type == action.type then
                        return true
                    end

                end

            end

        end
        return false

    end

    self.replace = function(bp, action, target, name)
        local bp = bp or false

        if bp then
            local helpers       = bp.helpers
            local action_type   = helpers['queue'].getType(bp, action)
            local action        = action or false
            local target        = target or false
            local name          = name or ''
            local data          = self.queue.data

            if action and target and data and name ~= '' then

                if #data > 0 then

                    for i,v in ipairs(data) do

                        if type(v) == 'table' and type(action) == 'table' and type(target) == 'table' and v.action and v.target then
                            local player = windower.ffxi.get_player() or false

                            if v.target.id == target.id and (name):match(v.action.en) and v.action.id ~= action.id then

                                -- Convert to self target.
                                if player and helpers['target'].onlySelf(bp, action) and target.id ~= player.id then
                                    target = windower.ffxi.get_mob_by_target('me')
                                end

                                if action_type == 'JobAbility' then
                                    helpers['queue'].remove(bp, bp.JA[v.action.en], target)
                                    self.queue:insert(i, {action=action, target=target, priority=0, attempts=1})
                                    break

                                elseif action_type == 'Magic' then
                                    helpers['queue'].remove(bp, bp.MA[v.action.en], target)
                                    self.queue:insert(i, {action=action, target=target, priority=0, attempts=1})
                                    break

                                elseif action_type == 'WeaponSkill' then
                                    helpers['queue'].remove(bp, bp.WS[v.action.en], target)
                                    self.queue:insert(i, {action=action, target=target, priority=0, attempts=1})
                                    break

                                end

                            elseif v.target.id == target.id and not (name):match(v.action.en) and v.action.id ~= action.id then

                                -- Convert to self target.
                                if player and helpers['target'].onlySelf(bp, action) and target.id ~= player.id then
                                    target = windower.ffxi.get_mob_by_target('me')
                                end
                                helpers['queue'].add(bp, action, target)
                                break

                            end

                        end

                    end

                end

            elseif #data == 0 then
                local player = windower.ffxi.get_player() or false

                -- Convert to self target.
                if player and helpers['target'].onlySelf(bp, action) and target.id ~= player.id then
                    target = windower.ffxi.get_mob_by_target('me')
                end
                helpers['queue'].add(bp, action, target)

            end

        end
        return false

    end

    self.updateCure = function(bp, action, target, priority)
        local bp = bp or false

        if bp then
            local helpers       = bp.helpers
            local action_type   = helpers['queue'].getType(bp, action)
            local action        = action or false
            local target        = target or false
            local data          = self.queue.data
            local priority      = T{'Cure IV','Cure V','Cure VI','Curaga III','Curaga IV','Curaga V','Curing Waltz IV','Curing Waltz V','Divine Waltz II'}

            if action and target and data then
                local update = false

                for i,v in ipairs(data) do
                    
                    if i > 1 then
                        
                        if type(v) == 'table' and type(action) == 'table' and type(target) == 'table' and v.action and v.target and (v.action.type == 'WhiteMagic' or v.action.type == 'Waltz') then

                            if v.target.id == target.id and v.action.en ~= action.en and ((v.action.en):match('Cure') or (v.action.en):match('Cura')) and not self.inQueue(bp, bp.MA[action.en], target) then
                                self.remove(bp, bp.MA[v.action.en], target)
                                update = true

                                --if priority:contains(action.en) then
                                    --self.queue:insert(i, {action=action, target=target, priority=0, attempts=1})
                                
                                --else
                                    self.queue:insert(i, {action=action, target=target, priority=0, attempts=1})

                                --end

                            elseif v.target.id == target.id and v.action.en ~= action.en and (v.action.en):match('Waltz') and not self.inQueue(bp, bp.JA[action.en], target) then
                                self.remove(bp, bp.JA[v.action.en], target)
                                update = true
                                
                                --if priority:contains(action.en) then
                                    --self.queue:insert(i, {action=action, target=target, priority=0, attempts=1})
                                
                                --else
                                    self.queue:insert(i, {action=action, target=target, priority=0, attempts=1})
                                
                                --end

                            end

                        end

                    end

                end

                if not update and priority:contains(action.en) then
                    helpers['queue'].addToFront(bp, action, target)

                elseif not update then
                    helpers['queue'].add(bp, action, target)

                end

            end

        end

    end

    self.pos = function(bp, x, y)
        local bp    = bp or false
        local x     = tonumber(x) or self.layout.pos.x
        local y     = tonumber(y) or self.layout.pos.y

        if bp and x and y then
            self.display:pos(x, y)
            self.layout.pos.x = x
            self.layout.pos.y = y
            self.writeSettings()
        
        elseif bp and (not x or not y) then
            bp.helpers['popchat'].pop('PLEASE ENTER AN "X" OR "Y" COORDINATE!')

        end

    end

    return self

end
return queue.new()
