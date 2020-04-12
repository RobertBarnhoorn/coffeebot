{ roles } = require 'unit_roles'

colors =
  WHITE:	 '#FFFFFF'
  SILVER:  '#C0C0C0'
  GRAY:    '#808080'
  BLACK:   '#000000'
  RED:     '#FF0000'
  MAROON:  '#800000'
  YELLOW:  '#FFFF00'
  OLIVE:   '#808000'
  LIME:    '#00FF00'
  GREEN:   '#008000'
  AQUA:    '#00FFFF'
  TEAL:    '#008080'
  BLUE:    '#0000FF'
  NAVY:    '#000080'
  FUCHSIA: '#FF00FF'
  PURPLE:  '#800080'

path_colors =
  [roles.UPGRADER]:    colors.OLIVE
  [roles.HARVESTER]:   colors.GREEN
  [roles.REPAIRER]:    colors.NAVY
  [roles.FORTIFIER]:   colors.NAVY
  [roles.BUILDER]:     colors.NAVY
  [roles.TRANSPORTER]: colors.TEAL
  [roles.RESERVER]:    colors.PURPLE
  [roles.CLAIMER]:     colors.FUCHSIA
  [roles.SOLDIER]:     colors.RED
  [roles.SNIPER]:      colors.YELLOW
  [roles.MEDIC]:       colors.LIME

module.exports = { colors, path_colors }
