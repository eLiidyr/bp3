local alias = {}
function alias.new()
    local self = {}

    self.capture = function(bp, commands)
        local bp        = bp or false
        local commands  = commands or false
        
        if bp and commands then
            local command = commands[2] or false

            if command then
                command = command:lower()

                if command == 'add' and commands[3] then
                    bp.helpers['alias'].add(bp, table.concat(commands, ' '))
                end

            end

        end

    end

    return self

end
return alias.new()
