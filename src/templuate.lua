--[[

  templuate
  A lightweight templating system for Lua

  Author: Rob Platt
  URL: https://github.com/RobPlatt/templuate

--]]

local TempLuate = { Helper = {}, Compiler = {} }

-- TempLuate.Helper.findFreeLongBrackets(str, [minLevel=0])
--
-- finds a level of lua long brackets that is not used in the given string str
-- if given minLevel, then the long bracket will be at least that level
--
-- The unused opening and closing brackets are returned as strings, along with
-- their level as follows:
--
-- returns (openingBracket:string, closingBracket:string, level:number)
--
TempLuate.Helper.findFreeLongBrackets = function(str, minLevel)
  minLevel = minLevel or 0
  local levelIndicator = string.rep('=', minLevel)
  local openingBracketToTry = '[' .. levelIndicator .. '['
  local closingBracketToTry = ']' .. levelIndicator .. ']'
  if string.find(str, openingBracketToTry, 1, true) or
     string.find(str, closingBracketToTry, 1, true) then
    return TempLuate.Helper.findFreeLongBrackets(str, minLevel+1)
  else
	return openingBracketToTry, closingBracketToTry, minLevel
  end
end

-- TempLuate.Helper.longBracketize(str)
--
-- returns the given string str enclosed in lua long brackets; the level
-- of the long brackets is chosen such that it doesn't conflict with any
-- brackets inside the string.
--
-- Example:
--
--   TempLuate.Helper.longBracketize('he]]o wor]=]d')
--     returns: '[==[he]]o wor]=]d]==]')
--
TempLuate.Helper.longBracketize = function(str)
  local openingBracket, closingBracket = TempLuate.Helper.findFreeLongBrackets(str)
  return openingBracket .. str .. closingBracket
end

-- TempLuate.Helper.expressionToString(source)
--
-- returns source as as string; if source is a function, it calls
-- that function with no arguments and returns the result.
--

-- append function for template generation
TempLuate.Compiler.append = function(target, str)
  table.insert(target.source, str)
end


TempLuate.Compiler.appendCode = function(target, str)
  TempLuate.Compiler.append(target, str)
end

TempLuate.Compiler.appendExpression = function(target, str)
  TempLuate.Compiler.append(target, target.putter .. '(' .. str .. ');')
 end
  
TempLuate.Compiler.appendText = function(target, str)
  --print("TEXT " .. str)
  TempLuate.Compiler.appendExpression(target, TempLuate.Helper.longBracketize(str))
end

TempLuate.Compiler.appendLua = function(target, str)
  --print("LUA " .. str)
  if loadstring("test__(" .. str .. ")") then
    TempLuate.Compiler.appendExpression(target, str)
  else
    TempLuate.Compiler.appendCode(target, str)
  end
end

TempLuate.Compiler.nextTagBracket = function(template, startpos)
  local openstart, openend = string.find(template, '%[%%', startpos)  
  local closestart, closeend = string.find(template, '%%%]', startpos)  
  if openstart == nil then return closestart, closeend end
  if closestart == nil then return openstart, openend end
  if openstart < closestart then return openstart, openend end
  return closestart
end

TempLuate.Compiler.luaMode = function(target, template, startpos)
  local nextstart, nextend = TempLuate.Compiler.nextTagBracket(template, startpos)
  local token
  if nextstart then
    token = string.sub(template, nextstart, nextend)
  end
  
  if token == nil or token == '[%' then
    local balancestart, balanceend = string.find(template, '%b[]', startpos-2)
	nextstart = balanceend
	nextend = balanceend
  end
  
  local endlua
  if nextstart then endlua = nextstart-1 end
  
  local text = string.sub(template, startpos, endlua)
  TempLuate.Compiler.appendLua(target, text)
  
  if nextstart ~= nil then
    return TempLuate.Compiler.textMode(target, template, nextend+1)
  end
end

TempLuate.Compiler.textMode = function(target, template, startpos)
  local nextstart, nextend = TempLuate.Compiler.nextTagBracket(template, startpos)
  
  local endtext
  if nextstart then endtext = nextstart-1 end
  local text = string.sub(template, startpos, endtext)
  TempLuate.Compiler.appendText(target, text)
  
  if nextstart == nil then return end
  
  local token = string.sub(template, nextstart, nextend)
  if token  == '[%' then
    return TempLuate.Compiler.luaMode(target, template, nextend+1)
  elseif token == '%]' then
    error("mismatched '%]'")
  else
    error("unexpected extraction " .. token)
  end
end

-- Process the template into the source so that it can be compiled
TempLuate.Compiler.process = function(target, template)
  -- The template begins in text rather than a lua tag
  return TempLuate.Compiler.textMode(target, template, 1)
end

TempLuate.Compiler.Default = {

  -- chunkname is nil by default

  assertOnCreate = true,
  
  -- method name used in source for outputting text
  --putter = "TempLuate_put__",
  putter = 'put',
  
  -- the default callback method evaluates the expressions
  -- into strings; any functions passed in are called without
  -- arguments. This allows anonymous functions in template tag
  -- expressions.
  callback_filter = function(self, source)
	if type(source) == "function" then
	  source = source()
	end
	return tostring(source)
  end,
    
  -- the run method executes the compiled template chunk, such
  -- that the callback is called with the component parts of the
  -- output filtered through the callback_filter
  run = function(self, callback)
	self.chunk(function(source)
	  callback(self:callback_filter(source))
    end)
  end,
  
  evaluate = function(self)
    local result = {}
    self:run(function(source)
	  table.insert(result, source)
	end)
	return table.concat(result)
  end
}

TempLuate.new = function(template, o)
  local o = o or {}
  for k,v in pairs(TempLuate.Compiler.Default) do
    if o[k] == nil then o[k] = v end
  end

  -- initialize generated source
  -- creates local putter from passed in variable
  o.source = {"local " .. o.putter .. " = ...;\n"}
  
  -- process the template into the source
  TempLuate.Compiler.process(o, template)
  
  -- merge table of strings into one table
  o.source = table.concat(o.source)
  -- compile the source into a Lua chunk
  o.chunk, o.error = loadstring(o.source, o.chunkname)
  
  if o.assertOnCreate then
    assert(o.chunk, o.error)
  end
  
  return o
end

setmetatable(TempLuate,
{
  __call = function(self, template, o)
    return TempLuate.new(template, o):evaluate()
  end
})

return TempLuate