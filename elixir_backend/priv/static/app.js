// Basic JavaScript file
document.addEventListener('DOMContentLoaded', () => {
  console.log('Application JS loaded');

  // Close flash messages
  const closeButtons = document.querySelectorAll('.alert-close');
  closeButtons.forEach(button => {
    button.addEventListener('click', () => {
      const alert = button.closest('.alert');
      if (alert) {
        alert.remove();
      }
    });
  });

  // Enable form validation if needed
  const forms = document.querySelectorAll('form[data-validate]');
  forms.forEach(form => {
    form.addEventListener('submit', (e) => {
      const requiredFields = form.querySelectorAll('[required]');
      let isValid = true;

      requiredFields.forEach(field => {
        if (!field.value.trim()) {
          isValid = false;
          field.classList.add('invalid');

          const errorMsg = document.createElement('div');
          errorMsg.className = 'error-message';
          errorMsg.textContent = 'This field is required';

          // Remove any existing error messages
          const existingError = field.parentNode.querySelector('.error-message');
          if (existingError) {
            existingError.remove();
          }

          field.parentNode.appendChild(errorMsg);
        } else {
          field.classList.remove('invalid');
          const existingError = field.parentNode.querySelector('.error-message');
          if (existingError) {
            existingError.remove();
          }
        }
      });

      if (!isValid) {
        e.preventDefault();
      }
    });
  });
});
