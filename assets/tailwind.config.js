module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: 'media',
  theme: {
    extend: {
      colors: {
        'strava-orange': '#fc4c02',
      },
       spacing: {
         '144': '36rem'
       }      
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
