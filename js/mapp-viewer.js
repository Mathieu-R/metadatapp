//const {ipcRenderer} = require('electron');

class Viewer extends HTMLElement {
  static get observedAttributes() {
    return [];
  }

  constructor() {
    super();
  }

  connectedCallback() {
    this.content = this.querySelector('.content');
    this.dragger = document.querySelector('.drag');
    this.dragger.addEventListener('metadata', evt => {
      console.log(evt.data);
      this.content.innerHTML = evt.data;
    });
  }

  disconnectedCallback() {

  }

  attributesChangedCallback(name, oldValue, newValue) {

  }
}

customElements.define('mapp-viewer', Viewer);
