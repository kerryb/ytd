module.exports = {
  mode: 'jit',
  content: [
    './js/**/*.js',
    '../lib/**/*.*ex'
  ],
  darkMode: 'media',
  theme: {
    extend: {
      colors: {
        'strava-orange': {
          light: '#fe7134',
          DEFAULT: '#fc4c01',
          dark: '#cb3e01',
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
