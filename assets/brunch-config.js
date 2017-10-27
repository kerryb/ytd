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
    assets: /^(static)/
  },
  paths: {
    watched: ["static", "css", "js", "vendor"],
    public: "../priv/static"
  },
  
  plugins: {
    babel: {
      ignore: [/vendor/]
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
      "js/app.js": ["js/app"]
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
