local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Universal Lock",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Universal Lock",
   LoadingSubtitle = "by notdvrk",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = true, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local Tab = Window:CreateTab("Main", 0) -- Title, Image

local Section = Tab:CreateSection("AimView")

local Button = Tab:CreateButton({
    Name = "Aimview Toggle",
    Callback = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local Workspace = game:GetService("Workspace")
        
        local LocalPlayer = Players.LocalPlayer
        local connections = {}
        local aimLines = {}
        
        -- Function to create/update aim line for a player
        local function updateAimLine(player)
            if player == LocalPlayer then return end
            if not player.Character then return end
            if not player.Character:FindFirstChild("Head") then return end
            
            local head = player.Character.Head
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            
            -- Get or create the aim line
            local aimLine = aimLines[player]
            if not aimLine then
                aimLine = Instance.new("Part")
                aimLine.Name = "AimLine_" .. player.Name
                aimLine.Anchored = true
                aimLine.CanCollide = false
                aimLine.BrickColor = BrickColor.new("Bright red")
                aimLine.Shape = Enum.PartType.Cylinder
                aimLine.Parent = Workspace
                aimLines[player] = aimLine
            end
            
            -- Calculate eye position (front of head where eyes are)
            local headCFrame = head.CFrame
            local eyePosition = headCFrame.Position + headCFrame.LookVector * 1.2 -- Move forward from head center
            
            -- Calculate look direction and end position
            local lookDirection = headCFrame.LookVector
            local endPosition = eyePosition + (lookDirection * 50) -- 50 studs length
            
            -- Calculate distance and position the cylinder
            local distance = (endPosition - eyePosition).Magnitude
            aimLine.Size = Vector3.new(distance, 0.2, 0.2)
            
            -- Position cylinder from eye position to end position
            local centerPosition = eyePosition + lookDirection * (distance / 2)
            aimLine.CFrame = CFrame.new(centerPosition, centerPosition + lookDirection) * CFrame.Angles(0, math.rad(90), 0)
        end
        
        -- Function to remove aim line for a player
        local function removeAimLine(player)
            if aimLines[player] then
                aimLines[player]:Destroy()
                aimLines[player] = nil
            end
        end
        
        -- Update all existing players
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                updateAimLine(player)
            end
        end
        
        -- Connect to RunService for continuous updates
        connections.heartbeat = RunService.Heartbeat:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    updateAimLine(player)
                end
            end
        end)
        
        -- Handle player leaving
        connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
            removeAimLine(player)
        end)
        
        -- Handle character respawning
        connections.playerAdded = Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Connect(function()
                wait(1) -- Wait for character to fully load
                updateAimLine(player)
            end)
        end)
    end,
})

local Section = Tab:CreateSection("Aimbot")

local Button = Tab:CreateButton({
    Name = "Aimbot Toggle",
    Callback = function()
        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local RunService = game:GetService("RunService")
        local Camera = workspace.CurrentCamera
        
        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
        
        local aimbotConnection
        local inputBeganConnection
        local inputEndedConnection
        local isRightMouseDown = false
        local FOV = 20
        local fovCircle
        local lockedTarget = nil -- Track the locked target
        
        -- Create FOV circle display
        local function createFOVCircle()
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "AimbotFOV"
            screenGui.Parent = PlayerGui
            
            fovCircle = Instance.new("Frame")
            fovCircle.Name = "FOVCircle"
            fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
            fovCircle.BackgroundTransparency = 1
            fovCircle.Parent = screenGui
            
            local circle = Instance.new("UIStroke")
            circle.Color = Color3.fromRGB(255, 0, 0) -- Red by default
            circle.Thickness = 2
            circle.Parent = fovCircle
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = fovCircle
            
            -- Calculate FOV circle size
            local function updateFOVSize()
                local viewportSize = Camera.ViewportSize
                local fovRadius = (viewportSize.Y / 2) * math.tan(math.rad(FOV / 2))
                fovCircle.Size = UDim2.new(0, fovRadius * 2, 0, fovRadius * 2)
            end
            
            updateFOVSize()
            Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateFOVSize)
        end
        
        -- Function to get closest player within FOV (only when no target is locked)
        local function getClosestPlayer()
            local closestPlayer = nil
            local shortestDistance = math.huge
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                    local head = player.Character.Head
                    local screenPoint, onScreen = Camera:WorldToScreenPoint(head.Position)
                    
                    if onScreen then
                        local screenPosition = Vector2.new(screenPoint.X, screenPoint.Y)
                        local distance = (screenPosition - screenCenter).Magnitude
                        local maxDistance = (Camera.ViewportSize.Y / 2) * math.tan(math.rad(FOV / 2))
                        
                        if distance <= maxDistance and distance < shortestDistance then
                            closestPlayer = player
                            shortestDistance = distance
                        end
                    end
                end
            end
            
            return closestPlayer
        end
        
        -- Function to aim at target
        local function aimAtTarget(target)
            if target and target.Character and target.Character:FindFirstChild("Head") then
                local head = target.Character.Head
                local targetPosition = head.Position
                local currentCFrame = Camera.CFrame
                local newCFrame = CFrame.lookAt(currentCFrame.Position, targetPosition)
                Camera.CFrame = newCFrame
            end
        end
        
        -- Function to check if locked target is still valid
        local function isTargetValid(target)
            return target and target.Character and target.Character:FindFirstChild("Head")
        end
        
        -- Create FOV display
        createFOVCircle()
        
        -- Handle right mouse button input
        inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                isRightMouseDown = true
            end
        end)
        
        inputEndedConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                isRightMouseDown = false
                lockedTarget = nil -- Clear locked target when releasing right mouse
            end
        end)
        
        -- Main aimbot loop
        aimbotConnection = RunService.Heartbeat:Connect(function()
            if isRightMouseDown then
                -- If we have a locked target and it's still valid, keep aiming at it
                if lockedTarget and isTargetValid(lockedTarget) then
                    fovCircle.UIStroke.Color = Color3.fromRGB(0, 255, 0) -- Green when locked
                    aimAtTarget(lockedTarget)
                else
                    -- If no locked target or target is invalid, find a new one
                    local target = getClosestPlayer()
                    if target then
                        lockedTarget = target -- Lock onto this target
                        fovCircle.UIStroke.Color = Color3.fromRGB(0, 255, 0) -- Green when locked
                        aimAtTarget(target)
                    else
                        lockedTarget = nil
                        fovCircle.UIStroke.Color = Color3.fromRGB(255, 0, 0) -- Red when no target
                    end
                end
            else
                -- Red when not aiming
                fovCircle.UIStroke.Color = Color3.fromRGB(255, 0, 0)
                lockedTarget = nil -- Clear target when not aiming
            end
        end)
    end,
})
