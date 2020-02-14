minBy = (xs, k) -> xs.reduce(((a, b) => if a[k] <= b[k] then a else b), {})

maxBy = (xs, k) -> xs.reduce(((a, b) => if a[k] >= b[k] then a else b), {})

module.exports = { minBy, maxBy }
