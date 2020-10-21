--< Module >--
local Queue = {}
Queue.__index = Queue

function Queue.new()
    local self = setmetatable({}, Queue)
    
    self.Elements = {}
    
    return self
end

function Queue:Enqueue(element)
    table.insert(self.Elements, element)
end

function Queue:Dequeue(index)
    return table.remove(self.Elements, index)
end

function Queue:Shift()
    local First = table.remove(self.Elements)

    table.insert(self.Elements, First)
end

function Queue:IsEmpty()
    return #self.Elements == 0
end

function Queue:Length()
    return #self.Elements
end

function Queue:Peek()
    return self.Elements[1]
end

return Queue