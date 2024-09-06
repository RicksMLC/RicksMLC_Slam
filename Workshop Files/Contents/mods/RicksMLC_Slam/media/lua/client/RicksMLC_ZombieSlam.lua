--RicksMLC_ZombieSlam.lua

local function getZombies(isoGridSquare) 
    local movingObjects = isoGridSquare:getMovingObjects()
    local zombies = {}
    for i=0, movingObjects:size()-1 do
        if instanceof(movingObjects:get(i), "IsoZombie") then
            zombies[#zombies+1] = movingObjects:get(i)
        end
    end
    return zombies
end

local origSprintKey = nil
local tickCount = 0
local maxTickCount = 80 -- 70, 90, 110, 120+ is a bit too long
local function OnRenderTick()
    tickCount = tickCount + 1
    if tickCount > maxTickCount then
        --DebugLog.log(DebugType.Mod, "ZombieSlam ticks:" .. tostring(maxTickCount))
        getCore():addKeyBinding("Sprint", origSprintKey)
        tickCount = 0
        -- TODO: Remove this commented out code when the number of ticks is solid.
        -- maxTickCount = maxTickCount + 10
        -- if maxTickCount > 80 then
        --     maxTickCount = 70
        -- end
        Events.OnRenderTick.Remove(OnRenderTick)
    end
end

local dummyHandWeapon = nil
local function Init()
    dummyHandWeapon = InventoryItemFactory.CreateItem("Plunger")
end

local function PayEnduranceCost(player, numZombies)
    local stats = player:getStats()
    local curEndurance = stats:getEndurance()
    local fitness = stats:getFitness()
    local strength = player:getPerkLevel(Perks.Strength)
    local baseCost = 0.5 - (0.02 * fitness + 0.04 * strength)
    local cost = baseCost * numZombies
    stats:setEndurance(curEndurance - math.min(cost, 0.1 * numZombies)) -- Ensures cost doesn't go below 0.1 * numZombies
end

local function OnObjectCollide(char, obj)
	if char ~= getPlayer() then return end

    if instanceof(obj, "IsoDoor") then
        if obj:IsOpen() then return end

        if char:isSprinting() then
            obj:ToggleDoor(char)
            local otherSideSquare = obj:getOtherSideOfDoor(char)
            local zombies = getZombies(otherSideSquare)
            if #zombies > 0 then
                for _, zombie in ipairs(zombies) do
                    zombie:setDefaultState()
                    zombie:Hit(dummyHandWeapon, char, 0, true, 0)
                    zombie:knockDown(false)
                end
                PayEnduranceCost(char, #zombies)
                origSprintKey = getCore():getKey("Sprint")
                getCore():addKeyBinding("Sprint", 0)
                char:setSprinting(false)
                Events.OnRenderTick.Add(OnRenderTick)
            end
        end
        return
    end
end

Events.OnGameStart.Add(Init)

Events.OnObjectCollide.Add(OnObjectCollide)