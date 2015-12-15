Meteor.startup ->
  etcd = (endpoint) ->
    endpoint = endpoint[...-1] if endpoint[-1..] is "/" # remove the trailing / if there is one

    get: (key) ->
      HTTP.get "#{endpoint}/#{key}"

    get: (key, callback) ->
      HTTP.get "#{endpoint}/#{key}", callback

    set: (key, value) ->
      HTTP.put "#{endpoint}/#{key}",
        params:
          value: value

    delete: (key) -> HTTP.del "#{endpoint}/#{key}"

    discover: (key, cb) ->
      @get "#{key}", (error, result) ->
        objects = []
        discover_ = (node) ->
          node?.nodes?.map (n) =>
            if n.value
              objects.push n
            else if n
              discover_ n
        if result?.data?.node
          discover_(result.data.node)
          cb null, objects
        else cb error, null

  @EtcdClient = etcd Settings.findOne().etcd
  Settings.find().observeChanges
    changed: -> @EtcdClient = etcd Settings.findOne().etcd
