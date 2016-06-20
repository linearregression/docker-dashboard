Highcharts = require 'highcharts/highstock'
_          = require 'lodash'

Template.index.helpers
  projectName: -> Settings.get('project').toUpperCase()
  appVersion: -> Helper.appVersion()
  appCount: -> ApplicationDefs.find().count()
  instanceCount: -> Instances.find().count()
  activeInstanceCount: -> Instances.find('meta.state': 'active').count()
  inactiveInstanceCount: -> Instances.find('meta.state': $not: 'active').count()
  tags: ->
    defs = ApplicationDefs.find({tags: $not: undefined}, fields: tags: 1).fetch()
    tagsAndCount = _.reduce defs, (memo, def) ->
      for tag in def.tags
        if memo[tag] then memo[tag] += 1 else memo[tag] = 1
      memo
    , {}
    tag: k, count: v for k,v of tagsAndCount
  createChart: ->
    systemStatus = _.fromPairs Swarm.findOne().swarm.SystemStatus
    systemStatus = _.mapKeys systemStatus, (value, key) ->
      key.trim().replace(/[\s\u2514]+/g, "")

Template.index.events
  'click .restart-tag': (e, tpl) -> Meteor.call 'restartTag', @tag
