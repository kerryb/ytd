module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    extend: {
      colors: {
        'strava-orange': '#fc4c02',
      }
    },
  },
  variants: {
    extend: {},
  },
  plugins: [],
}
