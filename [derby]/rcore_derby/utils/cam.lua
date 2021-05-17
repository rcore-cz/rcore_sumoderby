---------------------------------
-- Do not change anything here --
---------------------------------

local cinemaLook = false
local disableControl = false
local cameras = {}

function createCamera(name, pos, rot, fov)
    fov = fov or 60.0
    rot = rot or vector3(0, 0, 0)
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, false, 0)
    local try = 0
    while cam == -1 or cam == nil do
        Citizen.Wait(10)
        cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, false, 0)
        try = try + 1
        if try > 20 then
            return nil
        end
    end
    local self = {}
    self.cam = cam
    self.position = pos
    self.rotation = rot
    self.fov = fov
    self.name = name
    self.lastPointTo = nil
    self.pointTo = function(pos)
        self.lastPointTo = pos
        PointCamAtCoord(self.cam, pos.x, pos.y, pos.z)
    end
    self.render = function()
        SetCamActive(self.cam, true)
        RenderScriptCams(true, true, 1, true, true)
    end
    self.changeCam = function(newCam, duration)
        duration = duration or 3000
        SetCamActiveWithInterp(newCam, self.cam, duration, true, true)
    end
    self.destroy = function()
        SetCamActive(self.cam, false)
        DestroyCam(self.cam)
        cameras[name] = nil
    end
    self.changePosition = function(newPos, newPoint, newRot, duration)
        newRot = newRot or vector3(0, 0, 0)
        duration = duration or 4000
        if IsCamRendering(self.cam) then
            local tempCam = createCamera(string.format('tempCam-%s', self.name), newPos, newRot, self.fov)
            tempCam.render()
            if self.lastPointTo ~= nil then
                tempCam.pointTo(newPoint)
            end
            self.changeCam(tempCam.cam, duration)
            Citizen.Wait(duration)
            self.destroy()
            local newMain = deepCopy(tempCam)
            newMain.name = self.name
            self = newMain
            tempCam.destroy()
        else
            createCamera(self.name, newPos, newRot, self.fov)
        end
    end

    cameras[name] = self
    return self
end

function stopRendering()
    RenderScriptCams(false, false, 1, false, false)
end

function cinematicLook(toggle)
    cinemaLook = toggle
end

function disableControls(toggle)
    disableControl = toggle
end

function deepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

CreateThread(function()
    while true do
        Wait(5)
        if disableControl  then
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            DisableAllControlActions(3)
            DisableAllControlActions(4)
            DisableAllControlActions(5)
            DisableAllControlActions(6)
            DisableAllControlActions(7)
            DisableAllControlActions(8)
            DisableAllControlActions(9)
            DisableAllControlActions(10)
            DisableAllControlActions(11)
            DisableAllControlActions(12)
            DisableAllControlActions(13)
            DisableAllControlActions(14)
            DisableAllControlActions(15)
            DisableAllControlActions(16)
            DisableAllControlActions(17)
            DisableAllControlActions(18)
            DisableAllControlActions(19)
            DisableAllControlActions(20)
            DisableAllControlActions(21)
            DisableAllControlActions(22)
            DisableAllControlActions(23)
            DisableAllControlActions(24)
            DisableAllControlActions(25)
            DisableAllControlActions(26)
            DisableAllControlActions(27)
            DisableAllControlActions(28)
            DisableAllControlActions(29)
            DisableAllControlActions(30)
            DisableAllControlActions(31)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5)
        if cinemaLook then
            DrawRect(0.5, 0.075, 1.0, 0.15, 0, 0, 0, 255)
            DrawRect(0.5, 0.925, 1.0, 0.15, 0, 0, 0, 255)
            SetDrawOrigin(0.0, 0.0, 0.0, 0)
            DisplayRadar(false)
        else
            Wait(500)
        end
    end
end)