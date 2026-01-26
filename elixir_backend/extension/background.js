// Background service worker для Chrome extension

// Обработка установки расширения
chrome.runtime.onInstalled.addListener(() => {
  console.log('Links Manager extension installed');
  
  // Создаем контекстное меню для быстрого создания ссылки
  chrome.contextMenus.create({
    id: 'createLink',
    title: 'Создать короткую ссылку',
    contexts: ['page', 'link']
  });
});

// Обработка клика по контекстному меню
chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === 'createLink') {
    // Открываем popup с предзаполненными данными
    // Сохраняем URL и заголовок страницы для использования в popup
    const url = info.linkUrl || info.pageUrl || tab.url;
    const title = tab.title || '';
    
    await chrome.storage.local.set({
      pendingLinkUrl: url,
      pendingLinkTitle: title
    });
    
    // Открываем popup
    chrome.action.openPopup();
  }
});

// Обработка сообщений от content script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'createLinkFromPage') {
    // Открываем popup с предзаполненными данными
    chrome.action.openPopup();
    sendResponse({ success: true });
  }
  return true;
});
