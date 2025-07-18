/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
    './app/javascript/**/*.ts'
  ],
  theme: {
    extend: {
      colors: {
        'green': {
          800: '#166534',
          900: '#14532d',
        }
      }
    },
  },
  plugins: [],
  safelist: [
    'opacity-0',
    'opacity-100',
    'group-hover:opacity-100',
    'transition-opacity',
    'duration-200',
    'pointer-events-none',
    'absolute',
    'bottom-full',
    'left-1/2',
    'transform',
    '-translate-x-1/2',
    'mb-2',
    'px-3',
    'py-2',
    'bg-gray-900',
    'text-white',
    'text-xs',
    'rounded-lg',
    'w-64',
    'z-10'
  ]
} 