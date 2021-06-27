local canineModels = {}
canineModels["shepherd"] = "a_c_shepherd"
canineModels["husky"] = "a_c_husky"
canineModels["retriever"] = "a_c_retriever"

local canine = nil

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
    canine.inVehicle = false
    print("Canine " .. canine.name .. " has been created...")
  end
end

function canineSit()
  RequestAnimDict("creatures@retriever@amb@world_dog_sitting@base")
  while not HasAnimDictLoaded("creatures@retriever@amb@world_dog_sitting@base") do
    Citizen.Wait(0)
  end
  TaskPlayAnim(canine.entity, "creatures@retriever@amb@world_dog_sitting@base", "base", 8.0, 8.0, -1, 1, 0, 0, 0, 0)
end


function canineDelete()
  DeletePed(canine.entity)
  print("Canine " .. canine.name .. " has been deleted.")
  canine = nil
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

function canineFindTarget()

end

-- Placeholder till menu
Citizen.CreateThread(function() 
  while true do 
    Citizen.Wait(0)
    if IsControlJustPressed(0, 86) then
      if canine == nil then
        canineCreate(canineModels["retriever"], "Apollo")
      else
        canineDelete()
      end
    end

    canineIsSitting()
    if canine ~= nil then
      if IsPedInAnyVehicle(canine.entity, false) then
        canine.inVehicle = true
        if not canine.shouldSit then
          canine.shouldSit = true
        end
      end
      
      if canine.shouldSit and not canine.sitting then
        canineSit()
      elseif not canine.shouldSit and canine.sitting then
        ClearPedTasksImmediately(canine.entity)
      end

      if IsControlJustPressed(0, 250) then
        canine.shouldSit = not canine.shouldSit
      end
  
      if IsControlJustPressed(0, 252) then
        if not canine.inVehicle then
          TaskEnterVehicle(canine.entity, GetVehiclePedIsIn(PlayerPedId(), true), -1, 2, 2.0, 1, 0)
        else
          TaskLeaveVehicle(canine.entity, GetVehiclePedIsIn(canine.entity), 1)
          canine.shouldSit = false
        end
      end
    end
  end
end)