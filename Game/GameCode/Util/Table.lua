--------------------------------------------------------------------------------
-- Table decorate is useful for decorating objects
-- when using tables as classes.
-- @param src
-- @param arg1 - string=new key when string, needs arg2
-- @param arg2 - table=will extend all key/values     
--------------------------------------------------------------------------------
function table.decorate( src, arg1, arg2 )
    if not arg2 then
        if type(arg1)=="table" then
            for k,v in pairs( arg1 ) do
                if not src[k] then
                    src[k] = v
                elseif src[ k ] ~= v then
                    Logger.debug( "ERROR (table.decorate): Extension failed because key "..k.." exists.") 
                end   
            end
        end
    elseif type(arg1)=="string" and type(arg2)=="function" then
        if not src[arg1] then
            src[arg1] = arg2
        elseif src[ arg1 ] ~= arg2 then
            Logger.debug( "ERROR (table.decorate): Extension failed because key "..arg1.." exists.")
        end      
    end
end

--------------------------------------------------------------------------------
-- table.override and table.extend are very similar, but are made different
-- routines so that they wouldn't be confused
-- Author:Nenad Katic<br>
--------------------------------------------------------------------------------
function table.extend( src, dest )
    for k,v in pairs( src) do
        if not dest[k] then
            dest[k] = v
        end
    end
end

--------------------------------------------------------------------------------
-- Copies and overrides properties from src to dest.<br>
-- If onlyExistingKeys is true, it *only* overrides the properties.<br>
-- Author:Nenad Katic<br>
--------------------------------------------------------------------------------
function table.override( src, dest, onlyExistingKeys )
    for k,v in pairs( src ) do
        if not onlyExistingKeys then
            dest[k] = v
        elseif dest[k] then
            -- override only existing keys if asked for
            dest[k] = v
        end
    end
end

--------------------------------------------------------------------------------
-- Returns the position found by searching for a matching value from the array.
-- @param array table array
-- @param value Search value
-- @return If one is found the index. 0 if not found.
--------------------------------------------------------------------------------
function table.indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return 0
end

--------------------------------------------------------------------------------
-- Same as indexOf, only for key values (slower)
-- Author:Nenad Katic<br>
--------------------------------------------------------------------------------
function table.keyOf( src, val )
    for k, v in pairs( src ) do
        if v == val then
            return k
        end
    end
    return nil
end


--------------------------------------------------------------------------------
-- The shallow copy of the table.
-- @param src copy
-- @param dest (option)Destination
-- @return dest
--------------------------------------------------------------------------------
function table.copy(src, dest)
    dest = dest or {}
    for i, v in pairs(src) do
        dest[i] = v
    end
    return dest
end

--------------------------------------------------------------------------------
-- The deep copy of the table.
-- @param src copy
-- @param dest (option)Destination
-- @return dest
--------------------------------------------------------------------------------
function table.deepCopy(src, dest)
    dest = dest or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = M.deepCopy(v)
        else
            dest[k] = v
        end
    end
    return dest
end

--------------------------------------------------------------------------------
-- Adds an element to the table.
-- If the element was present, the element will return false without the need for additional.
-- If the element does not exist, and returns true add an element.
-- @param t table
-- @param o element
-- @return If it already exists, false. If you add is true.
--------------------------------------------------------------------------------
function table.insertElement(t, o)
    if M.indexOf(t, o) > 0 then
        return false
    end
    M.insert(t, o)
    return true
end

--------------------------------------------------------------------------------
-- This removes the element from the table.
-- If you have successfully removed, it returns the index of the yuan.
-- If there is no element, it returns 0.
-- @param t table
-- @param o element
-- @return index
--------------------------------------------------------------------------------
function table.removeElement(t, o)
    local i = M.indexOf(t, o)
    if i == 0 then
        return 0
    end
    M.remove(t, i)
    return i
end


--------------------------------------------------------------------------------
-- lua-enumerable
--------------------------------------------------------------------------------
table.includes = function(list, value)
  for i,x in ipairs(list) do
    if (x == value) then
      return(true)
    end
  end
  return(false)
end

table.detect = function(list, func)
  for i,x in ipairs(list) do
    if (func(x, i)) then
      return(x)
    end
  end
  return(nil)
end

table.without = function(list, item)
  return table.reject(list, function (x) 
    return x == item 
  end)
end

table.each = function(list, func)
  for i,v in ipairs(list) do
    func(v, i)
  end
end

table.every = function(list, func)
  for i,v in pairs(list) do
    func(v, i)
  end
end

table.select = function(list, func)
  local results = {}
  for i,x in ipairs(list) do
    if (func(x, i)) then
      table.insert(results, x)
    end
  end
  return(results)
end

table.reject = function(list, func)
  local results = {}
  for i,x in ipairs(list) do
    if (func(x, i) == false) then
      table.insert(results, x)
    end
  end
  return(results)
end

table.partition = function(list, func)
  local matches = {}
  local rejects = {}
  
  for i,x in ipairs(list) do
    if (func(x, i)) then
      table.insert(matches, x)
    else
      table.insert(rejects, x)
    end
  end
  
  return matches, rejects
end

table.merge = function(source, destination)
  for k,v in pairs(destination) do source[k] = v end
  return source
end

table.unshift = function(list, val)
  table.insert(list, 1, val)
end

table.shift = function(list)
  return table.remove(list, 1)
end

table.pop = function(list)
  return table.remove(list)
end

table.push = function(list, item)
  return table.insert(list, item)
end

table.collect = function(source, func) 
  local result = {}
  for i,v in ipairs(source) do table.insert(result, func(v)) end
  return result
end

table.empty = function(source) 
  return source == nil or next(source) == nil
end

table.present = function(source)
  return not(table.empty(source))
end

table.random = function(source)
  return source[math.random(1, #source)]
end

table.times = function(limit, func)
  for i = 1, limit do
    func(i)
  end
end

table.reverse = function(source)
  local result = {}
  for i,v in ipairs(source) do table.unshift(result, v) end
  return result
end

table.dup = function(source)
  local result = {}
  for k,v in pairs(source) do result[k] = v end
  return result
end

-- fisher-yates shuffle
function table.shuffle(t)
  local n = #t
  while n > 2 do
    local k = math.random(n)
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
  return t
end

table.keys = function(source)
  local result = {}
  for k,v in pairs(source) do
    table.push(result, k)
  end
  return result
end

