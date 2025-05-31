function widget:GetInfo()
    return {
        name = "Auto Base Grid Drawer",
        desc = "Draws base for NuttyB Raptor",
        author = "AlphaStrike",
        date = "2025",
        layer = 1,
        enabled = true
    }
end

VFS.Include('luaui/Headers/keysym.h.lua')

local gl = gl
local GL = GL
local GL_LINES = GL.LINES
local animating = false

-- Configuration
local lineWidth_GL = 2 -- line width for animating line
local previewLineWidth_GL = 1.5 -- line width for preview grid
local elevationGL = 2 -- or any small float like 1.5
local glLineColor = {1, 1, 0} -- Color for Animating line
local glPreviewLineColor = {1, 1, 1, 0.25} -- preview Color for Animating gridlines line
local tileSize = 192 -- grid tile size

--[[
local grid = { { 3 , 0 ,0 ,2 , 0, 0 ,1 },
               { 0 , 0 ,0 ,0 , 0, 0 ,0 }
            }
]]

--- MODIFY THIS TO CREATE YOUR BASE GRID
--- Lines in the Grid are drawn from the left side of the Grid block
-- 0 No lines
-- 1 Horizontal line
-- 2 Vertical line
-- 3 Both
local midLayout ={{3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2},
                 {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                 {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                 {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                 {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                 {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                 {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                 {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                 {3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2},
                 {3, 1, 1, 2, 3, 1, 1, 2, 3, 1, 1, 2, 3, 1, 1, 1, 2},
                 {2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 2},
                 {2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 2},
                 {2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 2, 2, 0, 0, 0, 2}}

local corneLayout = {{0, 0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2}, 
                     {0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                     {0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2}, 
                     {3, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                     {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2}, 
                     {2, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 2},
                     {2, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 2}, 
                     {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2},
                     {2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2}, 
                     {2, 0, 0, 0, 2, 2, 0, 0, 3, 1, 1, 1, 1, 1, 1, 1, 2},
                     {2, 0, 0, 0, 2, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2}, 
                     {2, 0, 0, 0, 2, 2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2},
                     {2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2}, 
                     {2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2},
                     {2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2},
                     {2, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 2}}


-- Support for multiple gridLayouts
-- Add your layouots to this list
local gridLayouts = {midLayout, corneLayout}
local index = 1
local grid = gridLayouts[index]

-- Simple bitwise AND for values 0 to 3
local function band(a, b)
    return ((a % 2) * (b % 2)) + (((math.floor(a / 2) % 2) * (math.floor(b / 2) % 2)) * 2)
end

local function DrawLine3D(x1, z1, x2, z2)
    local y1 = Spring.GetGroundHeight(x1, z1) + elevationGL
    local y2 = Spring.GetGroundHeight(x2, z2) + elevationGL
    gl.Vertex(x1, y1, z1)
    gl.Vertex(x2, y2, z2)
end

local function GetGridOrientation(pos, grid, tileSize)
    local cam = Spring.GetCameraVectors()
    local fx, fz = cam.forward[1], cam.forward[3]

    local forwardX, forwardZ
    if math.abs(fx) > math.abs(fz) then
        forwardX = fx > 0 and 1 or -1
        forwardZ = 0
    else
        forwardX = 0
        forwardZ = fz > 0 and 1 or -1
    end

    local rightX = -forwardZ
    local rightZ = forwardX

    local snapX = math.floor(pos[1] / tileSize) * tileSize
    local snapZ = math.floor(pos[3] / tileSize) * tileSize

    local numRows = #grid
    local numCols = #grid[1]

    local halfTile = tileSize * 0.5

    local colOffset = (numCols % 2 == 0) and -rightX * halfTile or 0
    local rowOffset = (numRows % 2 == 0) and -forwardX * halfTile or 0

    local originX = snapX - (numCols - 1) * rightX * tileSize * 0.5 - (numRows - 1) * forwardX * tileSize * 0.5 +
                        colOffset + rowOffset

    local colOffsetZ = (numCols % 2 == 0) and -rightZ * halfTile or 0
    local rowOffsetZ = (numRows % 2 == 0) and -forwardZ * halfTile or 0

    local originZ = snapZ - (numCols - 1) * rightZ * tileSize * 0.5 - (numRows - 1) * forwardZ * tileSize * 0.5 +
                        colOffsetZ + rowOffsetZ

    return {
        forwardX = forwardX,
        forwardZ = forwardZ,
        rightX = rightX,
        rightZ = rightZ,
        snapX = snapX,
        snapZ = snapZ,
        originX = originX,
        originZ = originZ,
        numRows = numRows,
        numCols = numCols
    }
end

local function BuildPreviewGridLines(pos)
    local horizontalLines = {}
    local verticalLines = {}

    local gridInfo = GetGridOrientation(pos, grid, tileSize)

    local forwardX, forwardZ = gridInfo.forwardX, gridInfo.forwardZ
    local rightX, rightZ = gridInfo.rightX, gridInfo.rightZ
    local originX, originZ = gridInfo.originX, gridInfo.originZ
    local rows, cols = gridInfo.numRows, gridInfo.numCols

    -- Build horizontal lines
    for r = 0, rows do
        local x1 = originX + 0 * rightX * tileSize + r * forwardX * tileSize
        local z1 = originZ + 0 * rightZ * tileSize + r * forwardZ * tileSize

        local x2 = x1 + (cols - 1) * rightX * tileSize
        local z2 = z1 + (cols - 1) * rightZ * tileSize

        table.insert(horizontalLines, {x1, z1, x2, z2})
    end

    -- Build vertical lines
    for c = 0, cols do
        local x1 = originX + c * rightX * tileSize + 0 * forwardX * tileSize
        local z1 = originZ + c * rightZ * tileSize + 0 * forwardZ * tileSize

        local x2 = x1 + (rows - 1) * forwardX * tileSize
        local z2 = z1 + (rows - 1) * forwardZ * tileSize

        table.insert(verticalLines, {x1, z1, x2, z2})
    end

    return horizontalLines, verticalLines
end

-- Build the lines based on camera + mouse position
local function BuildGridLines(pos)
    local lines = {}
    local gridInfo = GetGridOrientation(pos, grid, tileSize)

    local forwardX, forwardZ = gridInfo.forwardX, gridInfo.forwardZ
    local rightX, rightZ = gridInfo.rightX, gridInfo.rightZ
    local originX, originZ = gridInfo.originX, gridInfo.originZ
    local numRows, numCols = gridInfo.numRows, gridInfo.numCols
    -- Merge horizontal lines
    for row = 1, numRows do
        local startCol = nil
        for col = 1, numCols + 1 do
            local isLine = (col <= numCols and band(grid[row][col], 1) == 1)

            if isLine and not startCol then
                startCol = col
            elseif not isLine and startCol then
                local startX = originX + (startCol - 1) * rightX * tileSize + (numRows - row) * forwardX * tileSize
                local startZ = originZ + (startCol - 1) * rightZ * tileSize + (numRows - row) * forwardZ * tileSize
                local endX = originX + (col - 1) * rightX * tileSize + (numRows - row) * forwardX * tileSize
                local endZ = originZ + (col - 1) * rightZ * tileSize + (numRows - row) * forwardZ * tileSize
                table.insert(lines, {startX, startZ, endX, endZ})
                startCol = nil
            end
        end
    end

    -- Merge vertical lines
    for col = 1, numCols do
        local startRow = nil
        for row = 1, numRows + 1 do
            local isLine = (row <= numRows and band(grid[row][col], 2) == 2)

            if isLine and not startRow then
                startRow = row
            elseif not isLine and startRow then
                local startX =
                    originX + (col - 1) * rightX * tileSize + (numRows - startRow + 1) * forwardX * tileSize - forwardX *
                        tileSize
                local startZ =
                    originZ + (col - 1) * rightZ * tileSize + (numRows - startRow + 1) * forwardZ * tileSize - forwardZ *
                        tileSize
                local endX = originX + (col - 1) * rightX * tileSize + (numRows - row + 1) * forwardX * tileSize -
                                 forwardX * tileSize
                local endZ = originZ + (col - 1) * rightZ * tileSize + (numRows - row + 1) * forwardZ * tileSize -
                                 forwardZ * tileSize
                table.insert(lines, {startX, startZ, endX, endZ})
                startRow = nil
            end
        end
    end

    --[[
    -- Debug arrow (forward direction)
    local arrowLength = tileSize * 1.5
    table.insert(lines, {
        snapX, snapZ,
        snapX + forwardX * arrowLength,
        snapZ + forwardZ * arrowLength,
        "debug"
    })]]

    return lines
end

-- 🖍️ Draw the provided lines
local function DrawGridLines(lines)
    for _, line in ipairs(lines) do
        local x1, z1, x2, z2, tag = unpack(line)
        local color = (tag == "debug") and "0 1 1" or nil
        Spring.MarkerAddLine(x1, 0, z1, x2, 0, z2, false, color)
    end
end

-- Animate lines with mouse movement
local function animateGridLines(lines, lineWidth, lineColor)
    gl.DepthTest(true)
    gl.LineWidth(lineWidth)
    gl.Color(unpack(lineColor))

    gl.BeginEnd(GL.LINES, function()
        for _, line in ipairs(lines) do
            if line[5] ~= "debug" then
                local x1, z1, x2, z2 = unpack(line)
                DrawLine3D(x1, z1, x2, z2)
            end
        end
    end)

    gl.LineWidth(1)
    gl.DepthTest(false)
end

function widget:DrawWorld()
    if animating then
        local mx, my = Spring.GetMouseState()
        local _, pos = Spring.TraceScreenRay(mx, my, true)
        if pos then
            local lines = BuildGridLines(pos)
            animateGridLines(lines, lineWidth_GL, glLineColor)
            -- Draw preview gridlines
            local hLines, vLines = BuildPreviewGridLines(pos)
            animateGridLines(hLines, previewLineWidth_GL, glPreviewLineColor)
            animateGridLines(vLines, previewLineWidth_GL, glPreviewLineColor)
        end
    end
end

-- Draw lines
local function PlaceStaticGrid()
    local mx, my = Spring.GetMouseState()
    local _, pos = Spring.TraceScreenRay(mx, my, true)
    if pos then
        local lines = BuildGridLines(pos)
        DrawGridLines(lines)
    end
end
-- Horizontal Flip (Left ↔ Right)
local function FlipGridHorizontal(original)
    local flipped = {}
    for r = 1, #original do
        flipped[r] = {}
        for c = 1, #original[r] do
            flipped[r][c] = original[r][#original[r] - c + 1]
        end
    end
    return flipped
end

local function NextLayout()
    index = index + 1
    if index > #gridLayouts then
        index = 1  -- wrap around to the first layout
    end
    grid = gridLayouts[index]
    Spring.Echo("Switched to layout index: " .. index)
end

function widget:KeyPress(key, mods, isRepeat)
    if mods.ctrl and mods.alt then
        if key == KEYSYMS.A then
            if animating == true then
                animating = false
                Spring.Echo("[Grid] Animation stopped")
            else
                animating = true
                Spring.Echo("[Grid] Animation started")
            end
        elseif key == KEYSYMS.Q then
            animating = false
            Spring.Echo("[Grid] Grid placed")
            PlaceStaticGrid()
        elseif key == KEYSYMS.Z then
            Spring.Echo("[Grid] Grid Mirrored")
            -- Flip grid
            grid = FlipGridHorizontal(grid)
        elseif key == KEYSYMS.X then
            Spring.Echo("[Grid] Grid Next layout")
            -- NextLayout grid
             NextLayout()
             grid = gridLayouts[index]
        end
    end
end
