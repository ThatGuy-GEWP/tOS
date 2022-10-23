panelClass = require("panel") 
speaker = peripheral.find("speaker")
monitor = peripheral.wrap("right")

myPanel = panelClass:new(1,1,5,5)

term.setCursorBlink(false)
local w, h = term.getSize()
local files
local currentDirectory = ""
local curLine
local minLine
local maxLine
local renderOffset = 1
local maxLinesOnScreen = h-4

local rendering = false
local debugging = false

local buttons = {}

local currTerm = term.current()
local bWindow = window.create(currTerm, 1, 1, w, h, false)

function addButton(x, y)
    table.insert(buttons, {x, y, true}) -- if you need X/Y cords of {w,h} do {w+x, h+y} this converts to an x/y pos from w/h
    return #buttons
end

function setButtonState(buttonID, state)
    local x = buttons[buttonID][1]
    local y = buttons[buttonID][2]
    buttons[buttonID] = {x,y,state}
end

function setButtonPos(x, y, buttonID)
	if buttonID == nil then return end
    local buttonState = buttons[buttonID][3]
    buttons[buttonID] = {x, y, buttonState}
end

function withinRect(x1, y1, x2, y2, x, y)
    return (x >= x1 and x <= x2 and y >= y1 and y <= y2)
end

function startRender()
    if(not debugging) then
        if(rendering==true) then return end
        rendering = true
        term.redirect(bWindow)
    end
end

function endRender()
    if(not debugging) then
        rendering = false
        term.redirect(currTerm)
        bWindow.setVisible(true)
        bWindow.setVisible(false)
    end
end

function copyArray(ar)
    local newArray = {}
    for i=1, #ar do
        newArray[i] = ar[i]
    end
    return newArray
end

function combineTables(tableA, tableB)
    local finalTable = {}

    for a=1,#tableA do
        table.insert(finalTable, tableA[a])
    end
    for b=1,#tableB do
        table.insert(finalTable, tableB[b])
    end
    
    return finalTable
end

function openDirectory(dir)
    startRender()
    term.setBackgroundColor(colors.blue)
    term.clear()
    paintutils.drawFilledBox(1,1,w,1,colors.gray)
    term.setCursorPos(1,1)
    term.write("Directory: /"..dir)
    paintutils.drawPixel(w,1, colors.red)
    paintutils.drawPixel(w-2,1, colors.orange)
    files = fs.list(dir)

    filesA = {}
    Folders = {}

    for i=1, #files do
        if(fs.isDir(dir..files[i])) then
            table.insert(Folders, files[i])
        else
            table.insert(filesA, files[i])
        end
    end

    files = combineTables(Folders, filesA)
    
    curLine = 1
    minLine = 1
    maxLine = #files
    reloadStrings()
end

function playNote(instrument, pitch, volume)
    if(speaker == nil) then return end
    speaker.playNote(instrument, volume, pitch)
end

function clamp(val, min, max)
    if(val > max) then return max end
    if(val < min) then return min end
end

function getFileType(file, raw)
    raw = raw or false
    local fileTypes = {".lua",".txt"}
    local properNames = {"Lua File", "Text File"}
    for i=1,#fileTypes do
        if(string.find(file, fileTypes[i])~=nil) then
            if(raw)then
                return fileTypes[i]
            end
            return properNames[i]
        end
    end
    return "File"
end

local exitButton = addButton(w,1)
local restartButton = addButton(w-2,1)

function resize()
    setButtonPos(w,1,exitButton)
    setButtonPos(w-2,1,restartButton)
end

local editButton = addButton(1,1)
local runButton  = addButton(1,1)
setButtonState(editButton, false)
setButtonState(runButton, false)

function reloadLine(lineIndex, posY)
    local i = lineIndex
    term.setBackgroundColor(colors.blue)
    if(files[i] == nil) then paintutils.drawBox(1,posY, w, posY); return end
    local isCur = curLine == lineIndex
    if (isCur) then
        term.setBackgroundColor(colors.lightBlue) -- Light blue is nil because fuck logic right?
    end
    paintutils.drawBox(1,posY, w, posY) -- ClearsLine

    term.setCursorPos(2, posY)
    term.write(files[i])
    if(isCur) then
        term.setCursorPos(1, posY)
        term.write(">")

        term.setCursorPos(w-20, posY)
        term.write(">")
    end

    term.setCursorPos(w-19, posY)
    term.write("| ")

    if(fs.isDir(currentDirectory..files[i]) == true) then
        term.write("Folder")
    else
        local fileType = getFileType(files[i], true)
        term.write(getFileType(files[i]))
        local colorLast = term.getTextColor()
        local backLast = term.getBackgroundColor()
        term.setBackgroundColor(colors.gray)
        if((fileType == ".lua" or fileType == ".txt" or fileType == "File") and isCur) then
            term.setCursorPos(w-22, posY)
            term.setTextColor(colors.red)
            term.write("E")
            setButtonPos(w-22, posY, editButton)
            setButtonState(editButton, true)
        end
        if(fileType == ".lua" and isCur) then
            term.setCursorPos(w-24, posY)
            term.setTextColor(colors.green)
            term.write("R")
            setButtonPos(w-24, posY, runButton)
            setButtonState(runButton, true)
        end

        term.setTextColor(colorLast)
        term.setBackgroundColor(backLast)
    end

    term.setCursorPos(w-8, posY)
    term.write(" |")



    term.setCursorPos(w-6, posY)
    local size = fs.getSize(currentDirectory..files[i])
    if(not fs.isDir(currentDirectory..files[i])) then
        term.write(math.floor(fs.getSize(currentDirectory..files[i])/1000))
        term.setCursorPos(w-3, posY)
        term.write("KB")
    end
    term.setBackgroundColor(colors.blue)
end

function reloadStrings()
    startRender()
    renderOffset = curLine < maxLinesOnScreen and 0 or curLine-maxLinesOnScreen
    setButtonState(editButton, false)
    setButtonState(runButton, false)

    for i=1, maxLinesOnScreen do
        reloadLine(i + renderOffset, i+2)
    end
    
    paintutils.drawBox(1,h, w,h, colors.gray)
    term.setCursorPos(2,h)

    endRender()
end

openDirectory(currentDirectory)
local lastDirectory = "/"

local exitButton = addButton(w,1)
local restartButton = addButton(w-2,1)

local running = true
local restarting = false

while running do
    local event, AA,BB,CC,DD,EE,FF,GG = os.pullEvent() -- pulls ALL events
    local eventData = {AA,BB,CC,DD,EE,FF,GG}

    if(event == "key") then -- If laggy try "and eventData[2] == false"? makes it so you cant hold
        local lCur = curLine
        local holding = eventData[2]
        if(keys.getName(eventData[1]) == "down") then -- Move selector down
            curLine = curLine+1 > maxLine and minLine or curLine+1
            renderOffset = curLine>maxLinesOnScreen and renderOffset + 1 or renderOffset

            if(not holding) then playNote("hat", math.random(19,21), 0.5) else playNote("xylophone", 24, 0.2) end
        end

        if(keys.getName(eventData[1]) == "up") then  -- Move selector up
            curLine = curLine-1 < minLine and maxLine or curLine-1
            if(not holding) then playNote("hat", math.random(19,21), 0.5) else playNote("xylophone", 24, 0.2) end
        end

        if(keys.getName(eventData[1]) == "enter") then -- Move forward in directory
            if(fs.isDir(currentDirectory..files[curLine].."/")) then
                currentDirectory = currentDirectory..files[curLine].."/"
                term.setCursorPos(1,1)
                openDirectory(currentDirectory)
                playNote("pling", 24, 0.5)
            else
                playNote("basedrum", 10, 0.7)
            end
        end

        if(keys.getName(eventData[1]) == "backspace") then -- Move backward in directory
            if(currentDirectory == "") then 
                playNote("basedrum", 10, 0.7) 
            else
                local finalStr = ""
                local sep = {}
                for w in string.gmatch(currentDirectory,"(%w+)/") do
                    table.insert(sep, w)
                end
                table.remove(sep, #sep)
                for i=1,#sep do
                    finalStr = finalStr..sep[i].."/"
                end
                currentDirectory = finalStr
                openDirectory(currentDirectory)
                playNote("pling", 12, 0.5)
            end
        end

        selectedFile = files[curLine]
        clamp(renderOffset, 0, #files)
        reloadStrings()
    end

    if(event == "mouse_click" and eventData[1] == 1) then
        for i=1, #buttons do
            local x = eventData[2]
            local y = eventData[3]
            if(x==buttons[i][1] and y==buttons[i][2] and buttons[i][3] == true) then
                os.queueEvent("b_pressed", i)
            end
        end
    end

    if(event == "b_pressed") then
        if(eventData[1] == exitButton) then
            running = false
        end
        if(eventData[1] == restartButton) then
            running = false
            restarting = true
        end
        if(eventData[1] == editButton) then
            shell.openTab("rom/programs/edit", currentDirectory..files[curLine])
            playNote("bit", 8, 0.2)
        end
        if(eventData[1] == runButton) then
            shell.openTab(files[curLine])
            playNote("bit", 8, 0.2)
        end
    end
    if(event == "term_resize") then
        w, h = term.getSize()
        bWindow = window.create(currTerm, 1, 1, w, h, false)
        maxLinesOnScreen = h-4
        resize()
        openDirectory(currentDirectory)
    end
end
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorPos(1,1)
if(restarting) then
    print("restarting...")
    shell.run("data/system32/explorer.lua")
end