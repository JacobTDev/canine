local canineModels = {}
canineModels["shepherd"] = "a_c_shepherd"
canineModels["husky"] = "a_c_husky"
canineModels["retriever"] = "a_c_retriever"

local isSpawnMenuOpen
local canine = nil

Citizen.CreateThread(function()
  RegisterKeyMapping("caninespawnmenu", "Canine Spawn Menu", "keyboard", "F9")
  RegisterKeyMapping("caninesit", "Canine Sit", "keyboard", "Q")
  RegisterKeyMapping("caninefollow", "Canine Follow Handler", "keyboard", "e")
  RegisterKeyMapping("caninesettarget", "Set Canine Target", "keyboard", "c")
  RegisterKeyMapping("canineattacktarget", "Canine Attack Target", "keyboard", "n")
  RegisterKeyMapping("caninetogglevehicle", "Canine Enter/Exit Vehicle", "keyboard", "d") 

  TriggerEvent("chat:removeSuggestion", "/caninespawnmenu")
  TriggerEvent("chat:removeSuggestion", "/caninesit")
  TriggerEvent("chat:removeSuggestion", "/caninefollow")
  TriggerEvent("chat:removeSuggestion", "/caninesettarget")
  TriggerEvent("chat:removeSuggestion", "/canineattacktarget")
  TriggerEvent("chat:removeSuggestion", "/caninetogglevehicle")
end)

RegisterCommand("caninespawnmenu", function()
  if canine == nil then
    openSpawnMenu()
  else
    canineSendNotification("cannot open menu, K9 already exists. Try /removek9 in chat first.")
  end
end)

RegisterCommand("removek9", function()
  if canine ~= nil then
    canineDelete()
  else
    canineSendNotification("cannot remove K9. Try creating one first via the spawn menu.")
  end
end)

RegisterCommand("caninesit", function()
  if canine ~= nil and not canine.sittingInVehicle then
    if canine.attacking then
      canineStopAttack()
    end

    if canine.shouldSit then
      canineResetState()
      canine.shouldSit = false
      canineSendNotification("get up!", true)
    else
      canineResetState()
      canine.shouldSit = true
      canineSendNotification("sit!", true)
    end
  end
end)

RegisterCommand("caninefollow", function()
  if canine ~= nil then
    if canine.following then
      canineStopFollowingHandler()
    else
      canineFollowHandler()
    end
  end
end)

RegisterCommand("caninesettarget", function()
  if canine ~= nil then
    local hit, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())

    if hit and not IsPedInAnyVehicle(PlayerPedId(), false) then
      canine.target = entity
      canineSendNotification("new target has been set!", true)
    end
  end
end)

RegisterCommand("canineattacktarget", function()
  if canine ~= nil then
    if canine.target and DoesEntityExist(canine.target) and not IsEntityDead(canine.target) then 
      if canine.sittingInVehicle then
        canineSendNotification("cannot attack target, while in car!")
        return
      end

      canineResetState()
      ClearPedTasks(canine.entity)
      canineSendNotification("attack target!", true)
      canine.attacking = true

      TaskCombatPed(canine.entity, canine.target, 0, 16)
      SetPedKeepTask(canine.entity, true)
    else
      canineSendNotification("cannot attack target, it's either dead or does not exist!")
    end
  end
end)

RegisterCommand("caninetogglevehicle", function()
  if canine ~= nil then
    if not canine.sittingInVehicle then
      canineResetState()
      canineEnterVehicle()
    else
      canineResetState()
      canineExitVehicle()
    end
  end
end)

-------------------------- CANINE CREATION/DELATION ----------------------------
function canineRequestModel(modelHash)
  RequestModel(modelHash)
  while not HasModelLoaded(modelHash) do
    Citizen.Wait(0)
  end
end

function canineCreate(name, canineType)
  canine = {}
  local player = PlayerPedId()
  local playerPos = GetEntityCoords(player)
  local modelHash = GetHashKey(canineModels[canineType])

  canineRequestModel(modelHash)
  local canineEntity = CreatePed(28, modelHash, playerPos.x + 0.4, playerPos.y + 0.4, playerPos.z, 
        GetEntityHeading(player), true, true)
        
  if not canineEntity then
    canineSendNotification("unable to create canine!", false)
    return
  else
    canineResetState()
    canine.name = name
    canine.entity = canineEntity
    canine.shouldSit = true
    
    local weaponHash = GetHashKey("WEAPON_ANIMAL") 
    GiveWeaponToPed(canine.entity, weaponHash, 200, true, true);

    SetPedCombatMovement(canine.entity, 2)
    SetPedCombatAttributes(canine.entity, 5, true)
    SetPedCombatAttributes(canine.entity, 46, true)
    SetPedCombatAbility(canine.entity, 100)
    SetPedCombatRange(canine.entity, 2)
    SetPedFleeAttributes(canine.entity, 0, 0)

    canineSendNotification("has been created!", true)
  end
end

function canineDelete()
  DeletePed(canine.entity)
  canineSendNotification("has been removed!", true)
  canine = nil
end
--------------------------------------------------------------------------------

-------------------------------- CANINE VEHICLE --------------------------------
function canineEnterVehicle()
  local player = PlayerPedId()
  local handlerVehicle = GetVehiclePedIsIn(player, true)
  local dist = #(GetEntityCoords(handlerVehicle) - GetEntityCoords(canine.entity))
  
  if dist <= 5 then 
    Citizen.CreateThread(function()
      canineSendNotification("enter vehicle!", true)
      SetVehicleDoorOpen(handlerVehicle, 3, false, false)
      Citizen.Wait(1000)
      AttachEntityToEntity(canine.entity, handlerVehicle, GetEntityBoneIndexByName(handlerVehicle, "seat_pside_r"), 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, 0, false, false, false, 0, true)
      Citizen.Wait(1000)
      SetVehicleDoorShut(handlerVehicle, 3, false)
    end)

    canine.shouldSit = true
    canine.sittingInVehicle = true
  else
    canineSendNotification("too far away from vehicle, cannot enter!")
  end
end

function canineExitVehicle()
  local vehicle = GetVehiclePedIsIn(canine.entity, false)
  local caninePos = GetEntityCoords(canine.entity)
  canineSendNotification("exit vehicle!", true)
  DetachEntity(canine.entity, false, false)
  SetEntityCoords(canine.entity, caninePos.x , caninePos.y - 1.0, caninePos.z, false, true, false, false)
end
--------------------------------------------------------------------------------

--------------------------------- CANINE MISC ----------------------------------
function canineSit()
  RequestAnimDict("creatures@retriever@amb@world_dog_sitting@base")
  while not HasAnimDictLoaded("creatures@retriever@amb@world_dog_sitting@base") do
    Citizen.Wait(0)
  end
  TaskPlayAnim(canine.entity, "creatures@retriever@amb@world_dog_sitting@base", "base", 8.0, 8.0, -1, 1, 0, 0, 0, 0)
end

function canineIsSitting()
  if canine ~= nil then
    if IsEntityPlayingAnim(canine.entity, "creatures@retriever@amb@world_dog_sitting@base", "base", 3) then
      canine.sitting = true
    else
      canine.sitting = false
    end
  end
end

function canineStopAttack()
  if canine ~= nil and canine.attacking then
    canineSendNotification("stop attack!", true)
    canineResetState()
    SetPedKeepTask(canine.entity, false)
    ClearPedTasksImmediately(canine.entity)

    ClearPedTasks(canine.target)
    SetEntityHealth(canine.target, GetEntityMaxHealth(canine.target) * 0.6)
    canine.target = nil
  end
end

function canineFollowHandler()
  if not canine.following then
    if canine.attacking then
      canineStopAttack()
    end

    if canine.sittingInVehicle then
      canineSendNotification("cannot follow handler, while in car!")
      return
    end

    canineResetState()
    canine.shouldSit = false
    canine.following = true

    ClearPedTasks(canine.entity)
    TaskFollowToOffsetOfEntity(canine.entity, PlayerPedId(), 0.8, 0.0, 0.0, 7.0, -1, 1.5, true)
    SetPedKeepTask(canine.entity, true)
    canineSendNotification("follow me!", true)
  end
end

function canineStopFollowingHandler()
  if canine.following then
    canineResetState()
    SetPedKeepTask(canine.entity, false)
    ClearPedTasks(canine.entity)
  end
end
--------------------------------------------------------------------------------

Citizen.CreateThread(function() 
  while true do
    Citizen.Wait(0)
    if isSpawnMenuOpen then
      DisableControlAction(0,21,true) -- disable sprint
      DisableControlAction(0,24,true) -- disable attack
      DisableControlAction(0,25,true) -- disable aim
      DisableControlAction(0,47,true) -- disable weapon
      DisableControlAction(0,58,true) -- disable weapon
      DisableControlAction(0,263,true) -- disable melee
      DisableControlAction(0,264,true) -- disable melee
      DisableControlAction(0,257,true) -- disable melee
      DisableControlAction(0,140,true) -- disable melee
      DisableControlAction(0,141,true) -- disable melee
      DisableControlAction(0,142,true) -- disable melee
      DisableControlAction(0,143,true) -- disable melee
      DisableControlAction(0,75,true) -- disable exit vehicle
      DisableControlAction(27,75,true) -- disable exit vehicle
      DisableControlAction(0,32,true) -- move (w)
      DisableControlAction(0,34,true) -- move (a)
      DisableControlAction(0,33,true) -- move (s)
      DisableControlAction(0,35,true) -- move (d)
    end
  end
end)

-- Constant stuff
Citizen.CreateThread(function() 
  while true do 
    Citizen.Wait(0)
    if canine ~= nil then
      canineIsSitting()
      if canine.shouldSit and not canine.sitting then
        canineSit()
      elseif not canine.shouldSit and canine.sitting then
        ClearPedTasks(canine.entity)
      end
    end
  end
end)


----------------------------------- Utilities ----------------------------------
function canineResetState()
  canine.shouldSit = false
  canine.sittingInVehicle = false
  canine.following = false
  canine.attacking = false
end

function canineSendNotification(text, withCanineName)
  BeginTextCommandThefeedPost("STRING")
  if withCanineName then
    AddTextComponentSubstringPlayerName("~b~~h~" .. canine.name .. "~h~~b~~s~ " .. text)
  else
    AddTextComponentSubstringPlayerName("~b~~h~Canine~h~~b~:" .. "~s~ " .. text)
  end
  EndTextCommandThefeedPostTicker(true, false)
end
--------------------------------------------------------------------------------

RegisterNUICallback("nui:canine:spawncanine", function(data, cb)
  local name = data.name
  local canineType = data.canineType
  canineCreate(name, canineType)

  cb(data)
  closeSpawnMenu()
end)

RegisterNUICallback("nui:canine:closemenu", function(data, cb)
  closeSpawnMenu()
  cb(data)
end)

function openSpawnMenu()
  SendNUIMessage({
    open = true
  })
  SetNuiFocus(true, true)
  isSpawnMenuOpen = true
end

function closeSpawnMenu()
  SendNUIMessage({
    open = false
  })
  SetNuiFocus(false, false)
  isSpawnMenuOpen = false
end