//const {ipcRenderer} = require('electron');

class Viewer extends HTMLElement {
  static get observedAttributes() {
    return [];
  }

  constructor() {
    super();
  }

  connectedCallback() {

  }

  disconnectedCallback() {

  }

  attributesChangedCallback(name, oldValue, newValue) {

  }
}

customElements.define('mapp-viewer', Viewer);
