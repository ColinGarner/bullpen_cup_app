// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Auto-hide flash messages after 5 seconds
document.addEventListener('DOMContentLoaded', function() {
  const flashMessages = document.querySelectorAll('[data-flash-message]');
  
  flashMessages.forEach(function(message) {
    setTimeout(function() {
      message.style.opacity = '0';
      message.style.transform = 'translateX(-50%) translateY(-20px)';
      message.style.transition = 'all 0.3s ease-out';
      
      setTimeout(function() {
        message.remove();
      }, 300);
    }, 5000);
  });
});

// Re-run when Turbo loads new pages
document.addEventListener('turbo:load', function() {
  const flashMessages = document.querySelectorAll('[data-flash-message]');
  
  flashMessages.forEach(function(message) {
    setTimeout(function() {
      message.style.opacity = '0';
      message.style.transform = 'translateX(-50%) translateY(-20px)';
      message.style.transition = 'all 0.3s ease-out';
      
      setTimeout(function() {
        message.remove();
      }, 300);
    }, 5000);
  });
});
