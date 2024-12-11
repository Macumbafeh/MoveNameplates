local AddOnName, me = ...;
_VirtualPlates = me;
me.Frame = CreateFrame("Frame", nil, WorldFrame);

-- Removed scaling and kept only upward offset
local Plates = {};
me.Plates = Plates;
local PlatesVisible = {};
me.PlatesVisible = PlatesVisible;

local VERTICAL_OFFSET = 20

local function ResetPoint(Plate, Region, Point, RelFrame, ...)
    if (RelFrame == Plate) then
        local point, xOfs, yOfs = ...
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

local OriginalWorldFrameGetChildren = WorldFrame.GetChildren

local function PlatesScan(...)
    for Index = 1, select("#", ...) do
        local Frame = select(Index, ...);
        if (not Plates[Frame]) then
            local Region = Frame:GetRegions();
            if (Region and Region:GetObjectType() == "Texture" and Region:GetTexture() == [[Interface\TargetingFrame\UI-TargetingFrame-Flash]]) then
                PlateAdd(Frame);
            end
        end
    end
end

local ChildCount, NewChildCount = 0;
function me:WorldFrameOnUpdate(Elapsed)
    NewChildCount = self:GetNumChildren();
    if (ChildCount ~= NewChildCount) then
        ChildCount = NewChildCount;
        PlatesScan(OriginalWorldFrameGetChildren(self));
    end
end

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

function me.Frame:OnEvent(Event, ...)
    -- No events needed
end

WorldFrame:HookScript("OnUpdate", me.WorldFrameOnUpdate);
me.Frame:SetScript("OnEvent", me.Frame.OnEvent);
