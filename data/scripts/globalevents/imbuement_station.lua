local WORKBENCH_ID = 27547
local WORKBENCH_SLOTS = 4
local WORKBENCH_POSITIONS = {
    Position(93, 114, 7),
    -- Position(0, 0, 0),
    -- Position(0, 0, 0),
    -- Position(0, 0, 0),
}

local globalevent = GlobalEvent("ImbuementStation")
function globalevent.onStartup()
    for _, pos in ipairs(WORKBENCH_POSITIONS) do
        local tile = Tile(pos)
        if tile then
            local existing = tile:getItemById(WORKBENCH_ID)
            if existing then
                local container = Container(existing.uid)
                if not container then
                    existing:remove()
                    Game.createContainer(WORKBENCH_ID, WORKBENCH_SLOTS, pos)
                end
            else
                Game.createContainer(WORKBENCH_ID, WORKBENCH_SLOTS, pos)
            end
        end
    end
    return true
end
globalevent:register()
