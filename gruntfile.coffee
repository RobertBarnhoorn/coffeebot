(require 'dotenv').config()

module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-screeps')
  grunt.initConfig(
    screeps:
      options:
        email: process.env.EMAIL
        token: process.env.TOKEN
      dist:
        src: ['build/*.js']
  )
