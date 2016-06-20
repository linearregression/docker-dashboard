Meteor.startup ->
  Jobs  = JobCollection 'jobs'
  Jobs.remove {}

  jobs = [
    name: 'ETCD'
    url: Settings.get('etcd')
  ]

  for agent in Settings.get('agentUrl')
    jobs.push
      name: "Agent #{agent}"
      url: "#{agent}/ping"

  for j in jobs
    job = new Job Jobs, 'serviceCheck', j
    job.repeat
      repeats: Jobs.forever
      wait: 1000 * 60
    job.retry
      wait: 1000 * 60
    job.save()

  job = new Job Jobs, 'getSwarmInfo',
    name: 'SWARM'
    url: "http://localhost/swarm/info"
  job.repeat
    repeats: Jobs.forever
    wait: 5000
  job.retry
    wait: 1000
  job.save()

  Jobs.processJobs 'getSwarmInfo', (job, callback) ->
    HTTP.get job.data.url, (err, res) ->
      Swarm.upsert Swarm.findOne(),
        swarm: res.data
      job.done()
    callback()

  Jobs.processJobs 'serviceCheck', (job, callback) ->
    HTTP.get job.data.url, (err, data) ->
      if err or not data
        Services.upsert {name: job.data.name},
          name: job.data.name
          lastCheck: new Date()
          isUp: false

        job.fail err.content
      else
        Services.upsert {name: job.data.name},
          name: job.data.name
          lastCheck: new Date()
          isUp: true
        job.done()
    callback()


  Jobs.startJobServer()
