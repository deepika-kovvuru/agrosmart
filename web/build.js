const fs = require('fs');
const path = require('path');

const webDir = __dirname;
const targetDir = path.join(__dirname, '..', 'backend', 'static');

if (!fs.existsSync(targetDir)) {
  fs.mkdirSync(targetDir, { recursive: true });
}

const filesToCopy = ['index.html', 'styles.css', 'app.js', 'api.js', 'translations.js'];

filesToCopy.forEach(file => {
  const src = path.join(webDir, file);
  const dest = path.join(targetDir, file);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, dest);
    console.log(`Copied ${file} -> backend/static/${file}`);
  }
});

console.log('Successfully synced web app to backend/static!');
