{ find } = require 'lodash'
{ structures } = require 'structures'

MYSELF = find(structures).owner.username

module.exports = { MYSELF }
