Hapi = require 'hapi'

exports.startServer = (config, callback) ->

  port = process.env.PORT or config.server.port

  serverOptions =
    views:
      path: config.server.views.path
      engines:
        <% if (view === "handlebars") { %>hbs: require('handlebars')
        <% } else if (view === "jade") { %>jade: require('jade')
        <% } else if (view === "ejs") { %>ejs: require('ejs')
        <% } else if (view === "html") { %>html: require('ejs')
        <% } else if (view === "hogan") { %>hjs:
          module:
            compile: (template, options) ->
              engine = require('hogan.js')
              tmpl = engine.compile(template, options)
              (options) ->
                tmpl.render(options, {})
        <% } else if (view === "dust") { %>dust:
          compileMode: 'async'
          module:
            compile: (template, options, next) ->
              engine = require('dustjs-linkedin')
              compiled = engine.compileFn(template)
              next(null, (context, options, callback) ->
                compiled(context, callback))<% } %>

  server = new Hapi.Server 'localhost', port, serverOptions

  routeOptions =
    reload:    config.liveReload.enabled
    optimize:  config.isOptimize ? false
    cachebust: if process.env.NODE_ENV isnt "production" then "?b=#{(new Date()).getTime()}" else ''

  # Default Route
  server.route
    method: 'GET'
    path: '/'
    handler: (req, reply) ->
      <% if (view !== "html") { %>reply.view 'index', routeOptions
      <% } else { %>
      name = if config.isOptimize then "index-optimize" else "index"
      reply.view name, routeOptions<% } %>

  # Statically load public assets
  server.route
    method: 'GET'
    path: '/{param*}'
    handler:
      directory:
        path: 'public'

  server.start ->
    console.log 'Server running at:', server.info.uri

  callback server.listener