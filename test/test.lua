
templuate = require 'templuate'

assert(templuate.Helper.findFreeLongBrackets('hello') == '[[')
assert(templuate.Helper.findFreeLongBrackets('he[[o') == '[=[')
assert(templuate.Helper.findFreeLongBrackets('he]]o wor]=]d') == '[==[')
assert(templuate.Helper.longBracketize('he]]o wor]=]d') == '[==[he]]o wor]=]d]==]') 

print(templuate"hello world")

print(templuate[=[Hello [% function() return [[World!]] end %]]=])