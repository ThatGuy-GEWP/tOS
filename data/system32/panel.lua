Panel = {}

function Panel:new (x, y, w, h, comps, o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.comps = comps or {}
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.backgroundColor = colors.black
    self.outlineColor = colors.white
    self.hasOutline = true
    return o
end

function Panel:Update()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local lx, ly = term.getCursorPos()
    self:updateComponents()

    paintutils.drawFilledBox(x,y,(w+x),(w+y), self.backgroundColor)
    if(hasOutline) then
        paintutils.drawBox(x-1,y-1,(w+x)+1,(w+y)+1, self.outlineColor)
    end

    term.setCursorPos(lx, ly)
end

function Panel:SetColor(color)
    self.backgroundColor = color
end

function Panel:SetColorOutline(color)
    self.outlineColor = color
end

function Panel:updateComponents()
    for i=1,#self.comps do
        self.comps[i]:Update()
    end
end

return Panel


