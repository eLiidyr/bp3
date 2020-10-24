local distance  = {}
local player    = windower.ffxi.get_player()
local files     = require('files')
local texts     = require('texts')
local f = files.new(string.format('bp/helpers/settings/distance/%s_settings.lua', player.name))

if not f:exists() then
  f:write(string.format('return %s', T({}):tovstring()))
end

function distance.new()
    local self = {}

    -- Static Variables.
    self.settings   = dofile(string.format('%sbp/helpers/settings/distance/%s_settings.lua', windower.addon_path, player.name))
    self.layout     = self.settings.layout or {pos={x=420, y=865}, colors={text={alpha=255, r=245, g=200, b=20}, bg={alpha=200, r=0, g=0, b=0}, stroke={alpha=255, r=0, g=0, b=0}}, font={name='Mulish', size=9}, padding=4, stroke_width=1, draggable=false}
    self.display    = texts.new('', {flags={draggable=self.layout.draggable}})
    self.important  = string.format('%s,%s,%s', 25, 165, 200)

    -- Public Variables.
    self.distance = nil

    -- Private Functions
    local persist = function()

        if self.settings then
            self.settings.update    = self.update
            self.settings.layout    = self.layout
            self.settings.important = self.important

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
        self.display:hide()
        self.display:update()

    end
    resetDisplay()

    -- Static Functions.
    self.writeSettings = function()
        persist()

        if f:exists() then
            f:write(string.format('return %s', T(self.settings):tovstring()))

        elseif not f:exists() then
            f:write(string.format('return %s', T({}):tovstring()))

        end

    end
    self.writeSettings()

    self.render = function(bp)
        local bp        = bp or false
        local target    = windower.ffxi.get_mob_by_target('t') or false
        local color     = {string.format('%s,%s,%s', 25, 165, 200), string.format('%s,%s,%s', 25, 165, 200)}
        local update    = ''

        if target and target.distance then
            self.distance = (target.distance):sqrt()

            if self.distance > 0 and self.distance ~= nil then
                update = string.format('%02d.%d%d', tostring(self.distance):sub(1,2), tostring(self.distance):sub(4,4), tostring(self.distance):sub(5,5))
                self.display:text(string.format('{  \\cs(%s)%s\\cr  }', self.important, update))

                if not self.display:visible() then
                    local x = bp.helpers['target'].display:pos_x()
                    local y = bp.helpers['target'].display:pos_y()

                    if x and y then
                        self.display:pos(x-70, y)
                        self.display:show()

                    end

                end
                self.display:update()

            elseif self.distance == 0 or self.distance == nil and self.display:visible() then
                self.display:text('0')
                self.display:hide()

            end

        elseif self.display:visible() then
            self.display:hide()

        end

    end

    return self

end
return distance.new()