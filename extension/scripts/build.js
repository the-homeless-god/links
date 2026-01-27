const fs = require('fs-extra');
const path = require('path');

async function copyPublicFiles() {
  const publicDir = path.resolve(__dirname, '../public');
  const distDir = path.resolve(__dirname, '../dist');

  try {
    // Создаем dist если не существует
    await fs.ensureDir(distDir);

    // Копируем все файлы из extension (HTML, CSS, manifest, icons)
    const extensionDir = path.resolve(__dirname, '..');
    const filesToCopy = [
      'popup.html',
      'auth.html',
      'styles.css',
      'manifest.json',
    ];

    // Копируем файлы
    for (const file of filesToCopy) {
      const src = path.join(extensionDir, file);
      const dest = path.join(distDir, file);
      if (await fs.pathExists(src)) {
        await fs.copy(src, dest);
      }
    }

    // Копируем папку icons если существует
    const iconsDir = path.join(extensionDir, 'icons');
    const iconsDest = path.join(distDir, 'icons');
    if (await fs.pathExists(iconsDir)) {
      await fs.copy(iconsDir, iconsDest);
    }

    console.log('Static files copied successfully');
  } catch (err) {
    console.error('Error copying static files:', err);
    process.exit(1);
  }
}

copyPublicFiles();
