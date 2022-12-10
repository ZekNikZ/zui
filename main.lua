-- Utils
function box_chars(fg, bg)
    return {
        top_left = {text = "\156", fg = fg, bg = bg},
        top_right = {text = "\147", fg = bg, bg = fg},
        bottom_left = {text = "\138", fg = bg, bg = fg},
        bottom_right = {text = "\133", fg = bg, bg = fg},
        side_left = {text = "\149", fg = fg, bg = bg},
        side_right = {text = "\149", fg = bg, bg = fg},
        side_top = {text = "\140", fg = fg, bg = bg},
        side_bottom = {text = "\143", fg = bg, bg = fg},
        inside = {text = " ", fg = fg, bg = bg}
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
    local res = {root = rootEl}

    function res:draw()
        term.clear()
        self.root:draw()
    end

    function res:infiniteDraw()
        while true do
            self:draw()
            sleep(0.1)
        end
    end

    return res
end

function createBaseElement(id)
    local res = {
        id = id,
        x = 1,
        y = 1,
        w = 0,
        h = 0,
        bg = colors.black,
        fg = colors.white
    }

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
    function res:setBackground(val) self.fg = val end

    function res:resetColors()
        term.setTextColor(self:getForeground())
        term.setBackgroundColor(self:getBackground())
    end

    return res
end

function createContainerElement(id)
    local res = createBaseElement(id)

    res.children = {}
    function res:getChildren() return res.children end
    function res:setChildren(children) res.children = children end
    function res:addChild(child)
        table.insert(self:getChildren(), child)
    end
    function res:removeChild(id)
        for i = #self:getChildren(), 1, -1 do
            if self:getChildren()[i].id == id then
                table.remove(self:getChildren(), i)
            end
        end
    end
    function res:findId(id)
        for i = 1, #self:getChildren() do
            if self:getChildren()[i].id == id then
                return self:getChildren()[i]
            end
        end
    end
    function res:clearChildren() self:setChildren({}) end

    return res
end

function createVerticalLayout(id)
    local res = createContainerElement(id)

    function res:draw()
        self.children[1]:setX(self:getX())
        self.children[1]:setY(self:getY())
        self.children[1]:setWidth(self:getWidth())
        self.children[1]:setHeight(self:getHeight())
        self.children[1]:draw()
    end

    return res
end

function createFrameLayout(id, title, borderColor, child)
    local res = createBaseElement(id)

    res.title = title
    function res:getTitle() return self.title end
    function res:setTitle(val) self.title = val end

    borderColor = borderColor or self:getForeground()
    res.border = borderColor
    function res:getBorder() return self.border end
    function res:setBorder(val) self.border = val end

    if child == nil then
        res.base = createVerticalLayout(res:getId() .. "_child")
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
            term.setCursorPos(self:getX() + 2, self:getY())
            twrite(self:getTitle(), self:getBorder(), self:getBackground(),
                   true)
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
    function res:addChild(child)
        self.base:addChild(child)
    end
    function res:removeChild(id) self.base:removeChild(id) end
    function res:findId(id) self.base:findId(id) end
    function res:clearChildren() self.base:clearChildren() end

    return res
end

function createLabel(id, text)
    local res = createBaseElement(id)

    res.text = text
    function res:getText() return self.text end
    function res:setText(val) self.text = val end

    function res:draw()
        term.setCursorPos(self:getX(), self:getY())
        twrite(self:getText(), self:getForeground(), self:getBackground())
    end

    return res
end

local el = createFrameLayout("test", "Title", colors.red)
el:setWidth(20)
el:setHeight(6)
el:addChild(createLabel("titleLabel", "Test Label"))

local screen = createScreen(el)

screen:infiniteDraw()
