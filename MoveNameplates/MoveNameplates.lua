local AddOnName, me = ...;
_VirtualPlates = me;

-- Main frame anchored to WorldFrame
me.Frame = CreateFrame("Frame", nil, WorldFrame);

-- The storage tables
local Plates = {};
local PlatesVisible = {};

me.Plates = Plates;
me.PlatesVisible = PlatesVisible;

local VERTICAL_OFFSET = 50;


local function ResetPoint(Plate, Region, Point, RelFrame, ...)
    if (RelFrame == Plate) then
        local point, xOfs, yOfs = ...;
        Region:SetPoint(Point, Plates[Plate], point, xOfs, yOfs + VERTICAL_OFFSET);
    end
end

function me:PlateOnShow()
    local Visual = Plates[self];
    PlatesVisible[self] = Visual;
    Visual:Show();

    for Index, Region in ipairs(self) do
        for i = 1, Region:GetNumPoints() do
            ResetPoint(self, Region, Region:GetPoint(i));
        end
    end
end

function me:PlateOnHide()
    PlatesVisible[self] = nil;
    Plates[self]:Hide();
end

local function ReparentChildren(Plate, ...)
    local Visual = Plates[Plate];
    for Index = 1, select("#", ...) do
        local Child = select(Index, ...);
        if (Child ~= Visual) then
            local LevelOffset = Child:GetFrameLevel() - Plate:GetFrameLevel();
            Child:SetParent(Visual);
            Child:SetFrameLevel(Visual:GetFrameLevel() + LevelOffset);
            Plate[#Plate + 1] = Child;
        end
    end
end

local function ReparentRegions(Plate, ...)
    local Visual = Plates[Plate];
    for Index = 1, select("#", ...) do
        local Region = select(Index, ...);
        Region:SetParent(Visual);
        Plate[#Plate + 1] = Region;
    end
end

local function PlateAdd(Plate)
    -- Create the "Visual" frame
    local Visual = CreateFrame("Frame", nil, Plate);
    Plates[Plate] = Visual;

    Visual:Hide();
    Visual:SetPoint("TOP");
    Visual:SetSize(Plate:GetSize());

    ReparentChildren(Plate, Plate:GetChildren());
    ReparentRegions(Plate, Plate:GetRegions());
    Visual:EnableDrawLayer("HIGHLIGHT");

    Plate:SetScript("OnShow", me.PlateOnShow);
    Plate:SetScript("OnHide", me.PlateOnHide);
    if Plate:IsVisible() then
        me.PlateOnShow(Plate);
    end
end


local useRetailAPI = (C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlates);


if not useRetailAPI then
    local OriginalWorldFrameGetChildren = WorldFrame.GetChildren

    local function PlatesScan(...)
        for Index = 1, select("#", ...) do
            local Frame = select(Index, ...);
            if (not Plates[Frame]) then
                local Region = Frame:GetRegions();
                if (Region and Region:GetObjectType() == "Texture"
                   and Region:GetTexture() == [[Interface\TargetingFrame\UI-TargetingFrame-Flash]]) then
                    PlateAdd(Frame);
                end
            end
        end
    end

    local ChildCount = 0;
    function me:WorldFrameOnUpdate(Elapsed)
        local NewChildCount = self:GetNumChildren();
        if (ChildCount ~= NewChildCount) then
            ChildCount = NewChildCount;
            PlatesScan(OriginalWorldFrameGetChildren(self));
        end
    end

    WorldFrame:HookScript("OnUpdate", me.WorldFrameOnUpdate);

    -- Optionally override WorldFrame:GetChildren
    local Children = {};
    local function ReplaceChildren(...)
        local Count = select("#", ...);
        for Index = 1, Count do
            local Frame = select(Index, ...);
            Children[Index] = Plates[Frame] or Frame;
        end
        for Index = Count + 1, #Children do
            Children[Index] = nil;
        end
        return unpack(Children);
    end

    function WorldFrame:GetChildren(...)
        return ReplaceChildren(OriginalWorldFrameGetChildren(self, ...))
    end

else
    local EventFrame = CreateFrame("Frame");
    EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
    EventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
    EventFrame:RegisterEvent("NAME_PLATE_CREATED");

    EventFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "NAME_PLATE_CREATED" then
            

        elseif event == "NAME_PLATE_UNIT_ADDED" then
            -- arg1 is the unitID, e.g. "nameplate1"
            local plate = C_NamePlate.GetNamePlateForUnit(arg1);
            if plate and (not Plates[plate]) then
                -- This is a new plate we haven't re-parented yet
                PlateAdd(plate);
            end

        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            -- arg1 is the unitID
            local plate = C_NamePlate.GetNamePlateForUnit(arg1);
            if plate and Plates[plate] then
                -- Force the OnHide logic to run
                me.PlateOnHide(plate);
            end
        end
    end)
end


function me.Frame:OnEvent(Event, ...)
    -- in case we need an event
end
me.Frame:SetScript("OnEvent", me.Frame.OnEvent);
