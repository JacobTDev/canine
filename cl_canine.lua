local canineModels = {}
canineModels["shepherd"] = "a_c_shepherd"
canineModels["husky"] = "a_c_husky"
canineModels["retriever"] = "a_c_retriever"

local canine = nil

-------------------------- CANINE CREATION/DELATION ----------------------------
function canineRequestModel(modelHash)
  RequestModel(modelHash)
  while not HasModelLoaded(modelHash) do
    Citizen.Wait(0)
  end
end

function canineCreate(model, name)
  canine = {}
  local player = PlayerPedId()
  local playerPos = GetEntityCoords(player)
  local modelHash = GetHashKey(model)

  canineRequestModel(modelHash)
  local canineEntity = CreatePed(28, modelHash, playerPos.x, playerPos.y, playerPos.z, 
        GetEntityHeading(player), true, true)
        
  if not canineEntity then
    print("Unable to create canine...")
    return
  else
    canine.name = name
    canine.entity = canineEntity
    canine.shouldSit = true
    canine.sittingInVehicle = false
    canine.following = false
    canine.attacking = false
    canine.target = nil

    print(GetPedRelationshipGroupDefaultHash(canine.entity))
    print("Canine " .. canine.name .. " has been created...")
  end
end


function canineDelete()
  DeletePed(canine.entity)
  print("Canine " .. canine.name .. " has been deleted.")
  canine = nil
end
--------------------------------------------------------------------------------

-------------------------------- CANINE VEHICLE --------------------------------
function canineEnterVehicle()
  if not canine.sittingInVehicle then
    local handlerVehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    AttachEntityToEntity(canine.entity, handlerVehicle, GetEntityBoneIndexByName(handlerVehicle, "seat_pside_r"), 0.0, 0.0, 0.3, 0.0, 0.0, 0.0, 0, false, false, false, 0, true)
    canine.shouldSit = true
    canine.sittingInVehicle = true
  end
end

function canineExitVehicle()
  if canine.sittingInVehicle then
    local vehicle = GetVehiclePedIsIn(canine.entity, false)
    local caninePos = GetEntityCoords(canine.entity)
    DetachEntity(canine.entity, false, false)
    SetEntityCoords(canine.entity, caninePos.x + 5.0, caninePos.y, caninePos.z, false, true, false, false)
    canine.shouldSit = false
    canine.sittingInVehicle = false
  end
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

function canineFollowHandler()
  if not canine.following then
    if canine.attacking then
      print("Aborting attack, following handler instead.")
      canine.attacking = false
    end

    if canine.sittingInVehicle then
      print("Cannot follow handler, while in car... Aborting follow command")
      return
    end

    canine.shouldSit = false
    canine.following = true

    ClearPedTasks(canine.entity)
    TaskFollowToOffsetOfEntity(canine.entity, PlayerPedId(), 0.8, 0.0, 0.0, 7.0, -1, 1.5, true)
    SetPedKeepTask(canine.entity, true)
  end
end

function canineStopFollowingHandler()
  if canine.following then
    canine.following = false
    SetPedKeepTask(canine.entity, false)
    ClearPedTasks(canine.entity)
  end
end
--------------------------------------------------------------------------------

-- Control Checks
Citizen.CreateThread(function() 
  while true do
    Citizen.Wait(0)
    if canine ~= nil then
      hit, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
      -- Control E
      if IsControlJustPressed(0, 86) and hit and not IsPedInAnyVehicle(PlayerPedId(), false) then
        canine.target = entity
      end

      -- Control: F9
      if IsControlJustPressed(0, 56) and not canine.sittingInVehicle then
        canine.shouldSit = not canine.shouldSit
      end

      if IsControlJustPressed

      -- Control: G
      -- if IsControlJustPressed(0, 58) then
      --   if not canine.sittingInVehicle then
      --     canineEnterVehicle()
      --   else
      --     canineExitVehicle()
      --   end
      -- end

      if IsControlJustPressed(0, 58) then
        if canine.following then
          canineStopFollowingHandler()
        else
          canineFollowHandler()
        end
      end

      -- Control: B
      if IsControlJustPressed(0, 29) then
        canineDelete()
      end
    else
      -- Control: B
      if IsControlJustPressed(0, 29) then
        canineCreate(canineModels["retriever"], "Apollo")
      end
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