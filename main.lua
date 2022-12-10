-- Utils
function box_chars(fg, bg)
    return {
        top_left = {text = "\156", fg = fg, bg = bg},
        top_right = {text = "\147", fg = bg, bg = fg},
        bottom_left = {text = "\141", fg = fg, bg = bg},
        -- bottom_left = {text = "\138", fg = bg, bg = fg},
        bottom_right = {text = "\142", fg = fg, bg = bg},
        -- bottom_right = {text = "\133", fg = bg, bg = fg},
        side_left = {text = "\149", fg = fg, bg = bg},
        side_right = {text = "\149", fg = bg, bg = fg},
        side_top = {text = "\140", fg = fg, bg = bg},
        side_bottom = {text = "\140", fg = fg, bg = bg},
        -- side_bottom = {text = "\143", fg = bg, bg = fg},
        inside = {text = " ", fg = fg, bg = bg},
        title_left = {text = "\132", fg = fg, bg = bg},
        title_right = {text = "\136", fg = fg, bg = bg}
    }
end

function twrite(text, fg, bg, save)
    local oldFg = nil
    local oldBg = nil
    fg = fg or term.getTextColor()
    bg = bg or term.getBackgroundColor()

    if save == true then
        oldFg = term.getTextColor()
        oldBg = term.getBackgroundColor()
    end

    term.setTextColor(fg)
    term.setBackgroundColor(bg)
    term.write(text)

    if save == true then
        term.setTextColor(oldFg)
        term.setBackgroundColor(oldBg)
    end
end

function cwrite(data) twrite(data.text, data.fg, data.bg) end

-- UI stuff
function createScreen(rootEl)
    local w, h = term.getSize()

    local res = {root = rootEl}

    function res:draw()
        term.clear()
        self.root:setX(2)
        self.root:setY(2)
        self.root:setWidth(w - 2)
        self.root:setHeight(h - 2)
        self.root:draw()
    end

    function res:infiniteDraw(interval)
        interval = interval or 1
        while true do
            self:draw()
            sleep(interval)
        end
    end

    return res
end

function createBaseElement(id)
    local res = {id = id, x = 1, y = 1, w = 1, h = 1, bg = colors.black, fg = colors.white, layout_weight = 1}

    function res:getId() return self.id end

    function res:getX() return self.x end
    function res:setX(val) self.x = val end

    function res:getY() return self.y end
    function res:setY(val) self.y = val end

    function res:getWidth() return self.w end
    function res:setWidth(val) self.w = val end

    function res:getHeight() return self.h end
    function res:setHeight(val) self.h = val end

    function res:getBackground() return self.bg end
    function res:setBackground(val) self.bg = val end

    function res:getForeground() return self.fg end
    function res:setForeground(val) self.fg = val end

    function res:getLayoutWeight() return self.layout_weight end
    function res:setLayoutWeight(val) self.layout_weight = val end

    function res:resetColors()
        term.setTextColor(self:getForeground())
        term.setBackgroundColor(self:getBackground())
    end

    function res:findChild(id)
        print("checking element " .. self:getId())
        if id == self:getId() then
            return self
        else
            return nil
        end
    end

    return res
end

function createContainerElement(id)
    local res = createBaseElement(id)

    res.children = {}
    function res:getChildren() return res.children end
    function res:setChildren(children) res.children = children end
    function res:addChild(child) table.insert(self:getChildren(), child) end
    function res:removeChild(id)
        for i = #self:getChildren(), 1, -1 do
            if self:getChildren()[i].id == id then table.remove(self:getChildren(), i) end
        end
    end
    function res:findChild(id)
        local children = self:getChildren()
        for i = 1, #children do
            local potential = children[i]:findChild(id)
            if potential then return potential end
        end
    end
    function res:clearChildren() self:setChildren({}) end

    return res
end

function createLinearLayout(id, horizontal, gap)
    local res = createContainerElement(id)

    res.horizontal = horizontal or false
    res.gap = gap or 0

    function res:draw()
        local x = self:getX()
        local y = self:getY()
        local w = self:getWidth()
        local h = self:getHeight()

        if self.horizontal then
            -- Horizontal
            w = w - (#self:getChildren() - 1) * self.gap
            for i, child in ipairs(self:getChildren()) do
                child:setX(x)
                child:setY(y)
                child:setHeight(h)
                child:draw()
                x = x + child:getWidth() + self.gap
            end
        else
            -- Vertical
            h = h - (#self:getChildren() - 1) * self.gap
            for i, child in ipairs(self:getChildren()) do
                child:setX(x)
                child:setY(y)
                child:setWidth(w)
                child:draw()
                y = y + child:getHeight() + self.gap
            end
        end
    end

    return res
end

function createFrameLayout(id, title, borderColor, child)
    local res = createBaseElement(id)

    res.title = title
    function res:getTitle() return self.title end
    function res:setTitle(val) self.title = val end

    res.border = borderColor or self:getForeground()
    function res:getBorder() return self.border end
    function res:setBorder(val) self.border = val end

    if child == nil then
        local childId = nil
        if res:getId() then childId = res:getId() .. "_child" end
        res.base = createLinearLayout(childId)
    else
        res.base = child
    end

    function res:draw()
        term.setCursorPos(self:getX(), self:getY())

        characters = box_chars(self:getBorder(), self:getBackground())

        -- top row
        cwrite(characters.top_left)
        for i = 1, self:getWidth() - 2 do cwrite(characters.side_top) end
        cwrite(characters.top_right)

        if title ~= nil then
            term.setCursorPos(self:getX() + 1, self:getY())
            cwrite(characters.title_left)
            twrite(self:getTitle(), self:getBorder(), self:getBackground(), true)
            cwrite(characters.title_right)
        end

        -- sides
        for i = 1, self:getHeight() - 2 do
            term.setCursorPos(self:getX(), self:getY() + i)
            cwrite(characters.side_left)
            term.setCursorPos(self:getX() + self:getWidth() - 1, self:getY() + i)
            cwrite(characters.side_right)
        end

        -- bottom row
        term.setCursorPos(self:getX(), self:getY() + self:getHeight() - 1)
        cwrite(characters.bottom_left)
        for i = 1, self:getWidth() - 2 do cwrite(characters.side_bottom) end
        cwrite(characters.bottom_right)

        -- reset colors
        self:resetColors()

        -- children
        self.base:setX(self:getX() + 1)
        self.base:setY(self:getY() + 1)
        self.base:setWidth(self:getWidth() - 2)
        self.base:setHeight(self:getHeight() - 2)
        self.base:draw()
    end

    function res:getChildren() return self.base:getChildren() end
    function res:setChildren(children) self.base:setChildren(children) end
    function res:addChild(child) self.base:addChild(child) end
    function res:removeChild(id) self.base:removeChild(id) end
    function res:findChild(id) return self.base:findChild(id) end
    function res:clearChildren() self.base:clearChildren() end

    return res
end

function createSplitLayout(id, vertical, gap)
    local res = createContainerElement(id)

    res.vertical = vertical or false
    res.gap = gap or 0

    function res:draw()
        -- Compute total weight
        local total_weight = 0

        for i, child in ipairs(self:getChildren()) do total_weight = total_weight + child:getLayoutWeight() end

        if total_weight == 0 then return end

        -- Draw each child
        local x = self:getX()
        local y = self:getY()
        local w = self:getWidth()
        local h = self:getHeight()
        if self.vertical then
            -- Vertical
            h = h - (#self:getChildren() - 1) * self.gap
            local extra = h % total_weight
            for i, child in ipairs(self:getChildren()) do
                local height = math.floor(h * child:getLayoutWeight() / total_weight)

                if extra > 0 then
                    height = height + 1
                    extra = extra - 1
                end

                child:setX(x)
                child:setY(y)
                child:setWidth(w)
                child:setHeight(height)
                child:draw()
                y = y + height + self.gap
            end
        else
            -- Horizontal
            w = w - (#self:getChildren() - 1) * self.gap
            local extra = w % total_weight
            for i, child in ipairs(self:getChildren()) do
                local width = math.floor(w * child:getLayoutWeight() / total_weight)

                if extra > 0 then
                    width = width + 1
                    extra = extra - 1
                end

                child:setX(x)
                child:setY(y)
                child:setWidth(width)
                child:setHeight(h)
                child:draw()
                x = x + width + self.gap
            end
        end
    end

    return res
end

function createLabel(id, text, align, height, fg, bg)
    local res = createBaseElement(id)

    res.align = align or "left"
    if height then res:setHeight(height) end
    if fg then res:setForeground(fg) end
    if bg then res:setBackground(bg) end

    res.text = text
    function res:getText() return self.text end
    function res:setText(val) self.text = val end

    function res:draw()
        local lineToDrawOn = math.floor((self:getHeight() - 1) / 2)
        term.setTextColor(self:getForeground())
        term.setBackgroundColor(self:getBackground())

        for i = 1, lineToDrawOn do
            term.setCursorPos(self:getX(), self:getY() + i - 1)
            twrite(string.format("%-" .. self:getWidth() .. "s", " "))
        end

        term.setCursorPos(self:getX(), self:getY() + lineToDrawOn)
        if self.align == "left" then
            twrite(string.format("%-" .. self:getWidth() .. "s", self:getText()))
        elseif self.align == "right" then
            twrite(string.format("%" .. self:getWidth() .. "s", self:getText()))
        else
            local extraSpaces = math.floor((self:getWidth() - #self:getText()) / 2)
            twrite(string.format("%-" .. self:getWidth() .. "s", " "))
            term.setCursorPos(self:getX() + extraSpaces, self:getY() + lineToDrawOn)
            twrite(self:getText())
        end

        for i = lineToDrawOn + 1, self:getHeight() - 1 do
            term.setCursorPos(self:getX(), self:getY() + i)
            twrite(string.format("%-" .. self:getWidth() .. "s", " "))
        end
    end

    return res
end

function createProgressBar(id, height, fg, bg)
    local res = createBaseElement(id)

    if height then res:setHeight(height) end
    res:setForeground(fg or colors.green)
    res:setBackground(bg or colors.gray)

    res.value = 5
    function res:getValue() return self.value end
    function res:setValue(val) self.value = val end
    res.max = 10
    function res:getMax() return res.max end
    function res:setMax(val) res.max = val end

    function res:draw()
        local leftSize = math.floor(self:getWidth() * self:getValue() / self:getMax())
        local rightSize = self:getWidth() - leftSize

        for i = 1, self:getHeight() do
            term.setCursorPos(self:getX(), self:getY() + i - 1)

            term.setBackgroundColor(self:getForeground())
            twrite(string.format("%-" .. leftSize .. "s", " "))

            term.setBackgroundColor(self:getBackground())
            twrite(string.format("%-" .. rightSize .. "s", " "))
        end
    end

    return res
end

function createSpace(id, amount)
    local res = createBaseElement(id)

    amount = amount or 1
    res:setHeight(amount)
    res:setWidth(amount)

    function res:draw() end

    return res
end

local sectionReactor = createFrameLayout(nil, "Fission Reactor", colors.lightGray)
sectionReactor:addChild(createLabel(nil, "Coolant"))
sectionReactor:addChild(createProgressBar("reactorProgressCoolant", 1, colors.lightBlue))
sectionReactor:addChild(createSpace())
sectionReactor:addChild(createLabel(nil, "Fissile Fuel"))
sectionReactor:addChild(createProgressBar("reactorProgressFuel", 1, colors.purple))
sectionReactor:addChild(createSpace())
sectionReactor:addChild(createLabel(nil, "Waste"))
sectionReactor:addChild(createProgressBar("reactorProgressWaste", 1, colors.brown))

local sectionBoiler = createFrameLayout(nil, "Thermoelectric Boiler", colors.brown)
sectionBoiler:addChild(createLabel(nil, "Input Coolant"))
sectionBoiler:addChild(createProgressBar("boilerProgressInput", 1, colors.red))
sectionBoiler:addChild(createSpace())
sectionBoiler:addChild(createLabel(nil, "Output Coolant"))
sectionBoiler:addChild(createProgressBar("boilerProgressOutput", 1, colors.green))

local sectionTurbine = createFrameLayout(nil, "Industrial Turbine", colors.blue)
sectionTurbine:addChild(createLabel(nil, "Steam Buffer"))
sectionTurbine:addChild(createProgressBar("turbineProgressSteam", 1, colors.lightGray))
sectionTurbine:addChild(createSpace())
sectionTurbine:addChild(createLabel(nil, "Energy Buffer"))
sectionTurbine:addChild(createProgressBar("turbineProgressEnergy", 1, colors.green))

local sectionEnergy = createFrameLayout(nil, "Base Energy Storage", colors.green)
sectionEnergy:addChild(createLabel(nil, "Energy Buffer"))
sectionEnergy:addChild(createProgressBar("energyProgressEnergy", 1, colors.green))
sectionEnergy:addChild(createSpace())
sectionEnergy:addChild(createLabel("energyLabelIO", "+1000 FE/t", "center", 1, colors.blue))

local left = createSplitLayout("left", true, 1)
left:addChild(sectionReactor)
left:addChild(sectionBoiler)
left:addChild(sectionTurbine)

local right = createSplitLayout("right", true)
right:addChild(sectionEnergy)

local root = createSplitLayout("root", false, 1)
root:addChild(left)
root:addChild(right)

local screen = createScreen(root)
screen:infiniteDraw(1)
