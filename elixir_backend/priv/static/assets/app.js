// Базовая интеграция с Phoenix LiveView
document.addEventListener('DOMContentLoaded', () => {
  // Закрытие флеш-сообщений
  document.addEventListener('click', (event) => {
    if (event.target.matches('.alert-close')) {
      const alert = event.target.closest('.alert');
      if (alert) {
        alert.remove();
      }
    }
  });

  // Настройка темы
  const setTheme = (theme) => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  };

  // Проверка сохраненной темы
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme) {
    setTheme(savedTheme);
  }

  // Обработчик переключения темы (если есть такая кнопка в интерфейсе)
  document.addEventListener('click', (event) => {
    if (event.target.matches('[data-theme-toggle]')) {
      const currentTheme = document.documentElement.getAttribute('data-theme') || 'light';
      const newTheme = currentTheme === 'light' ? 'dark' : 'light';
      setTheme(newTheme);
    }
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
