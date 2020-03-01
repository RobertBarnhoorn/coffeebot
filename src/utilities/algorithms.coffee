# If f is a string, find the element whose attribute with that name is the minimum
# If f is a function, find the element which, after have f applied to it, is the minimum
minBy = (xs, f) ->
  if typeof f is 'string'
    xs.reduce ((a, b) -> if a[f] <= b[f] then a else b), {}
  else
    xs.reduce ((a, b) -> if f(a) <= f(b) then a else b), {}

# If f is a string, find the element whose attribute with that name is the maximum
# If f is a function, find the element which, after have f applied to it, is the maximum 
maxBy = (xs, f) ->
  if typeof f is 'string'
    xs.reduce ((a, b) -> if a[f] >= b[f] then a else b), {}
  else
    xs.reduce ((a, b) -> if f(a) >= f(b) then a else b), {}

module.exports = { minBy, maxBy }
