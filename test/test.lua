
assert(TempLuate.Helper.findFreeLongBrackets('hello') == '[[')
assert(TempLuate.Helper.findFreeLongBrackets('he[[o') == '[=[')
assert(TempLuate.Helper.findFreeLongBrackets('he]]o wor]=]d') == '[==[')
assert(TempLuate.Helper.longBracketize('he]]o wor]=]d') == '[==[he]]o wor]=]d]==]') 

print(
  TempLuate.new([=[Hello [% function() return [[World!]] end %]]=],
  {assertOnCreate=false}):evaluate())
