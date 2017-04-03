exports.config = {
  files: {
    javascripts: {
      joinTo: "js/app.js"
    },
    stylesheets: {
      joinTo: "css/app.css",
      order: {
        after: ["web/static/css/app.scss"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },
conventions: {
    assets: /^(web\/static\/assets)/
  },
  paths: {
    watched: [
      "web/static",
      "test/static"
    ],
    public: "priv/static"
  },
  
  plugins: {
    babel: {
      ignore: [/web\/static\/vendor/]
    },
    copycat: {
      "fonts": ["node_modules/bootstrap-sass/assets/fonts/bootstrap"]
    },
    sass: {
      options: {
        includePaths: ["node_modules/bootstrap-sass/assets/stylesheets"],
        precision: 8
      }
    }
  },
  
  modules: {
    autoRequire: {
      "js/app.js": ["web/static/js/app"]
    }
  },
  
  npm: {
    enabled: true,
    globals: {
      $: 'jquery',
      jQuery: 'jquery',
      bootstrap: 'bootstrap-sass'
    }
  }
}
