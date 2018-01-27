const {app, BrowserWindow, ipcMain} = require('electron');
let mainWindow;

class App {
  constructor () {
    this.createWindow = this.createWindow.bind(this);
    this.addEventListeners();
  }

  createWindow () {
    mainWindow = new BrowserWindow({width: 1800, height: 1200, title: 'metadatapp'});
    mainWindow.loadURL(`file://${__dirname}/index.html`);

    mainWindow.on('closed', _ => mainWindow = null);
  }

  addEventListeners () {


    app.on('ready', this.createWindow);

    app.on('window-all-closed', _ => {
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });

    app.on('activate', _ => {
      if (mainWindow === null) {
        this.createWindow();
      }
    });
  }
}

new App();
