const {ipcRenderer} = require('electron');
const fs = require('fs');
const promisify = require('util-promisify');
const mm = require('musicmetadata');

class Dragger extends HTMLElement {
  static get observedAttributes() {
    return [];
  }

  constructor() {
    super();
    this.getMetadataButton = this.querySelector('.get-metadata');
    this.musics = [];
    this.onDrop = this.onDrop.bind(this);
    this.getMetadata = this.getMetadata.bind(this);
  }

  connectedCallback() {
    this.addEventListeners();
  }

  onDrop (evt) {
    evt.preventDefault();
    const musics = Array.from(evt.dataTransfer.files);
    this.musics.push(...musics);
    console.log(musics);
  }

  getMetadata (evt) {
    this.musics.forEach(async music => {
      try {
        const readableStream = fs.createReadStream(music.path);
        const metadata = await promisify(mm)(readableStream);
        console.log(metadata);
        readableStream.close();
      } catch (err) {
        console.error(err);
      }
    });
  }

  addEventListeners () {
    this.addEventListener('dragover', evt => evt.preventDefault());
    this.addEventListener('drop', this.onDrop);
    this.getMetadataButton.addEventListener('click', this.getMetadata);
  }

  disconnectedCallback() {

  }

  attributesChangedCallback(name, oldValue, newValue) {

  }
}

customElements.define('mapp-dragger', Dragger);
