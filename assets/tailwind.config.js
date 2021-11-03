module.exports = {
  mode: 'jit',
  purge: [
    './js/**/*.js',
    '../lib/**/*.*ex'
  ],
  darkMode: 'media',
  theme: {
    extend: {
      colors: {
        'strava-orange': {
          light: '#fd7135',
          DEFAULT: '#fc4c02',
          dark: '#ca3e02',
        },
      },
       spacing: {
         '144': '36rem'
       }      
    },
  },
  variants: {
    extend: {
      display: ['dark'],
    },
  },
  plugins: [],
}
