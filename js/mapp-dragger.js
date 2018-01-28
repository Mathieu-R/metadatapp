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
  }

  getMetadata (evt) {
    const metadataArrayPromise = this.musics.reduce(async (current, music) => {
      try {
        const readableStream = fs.createReadStream(music.path);
        const metadata = await promisify(mm)(readableStream);
        await promisify(fs.writeFile)(__dirname + `/artworks/${metadata.album}`, metadata.picture[0].data);
        const c = await current;
        c.push(this.simpleMetadataObject(metadata));
        readableStream.close();
        return c;
      } catch (err) {
        console.error(err);
      }
    }, []);

    metadataArrayPromise.then(metadataArray => {
      const customEvent = new CustomEvent('metadata', {
        bubbles: true,
        data: JSON.stringify(metadataArray)
      });
      this.dispatchEvent(customEvent);
    });
  }

  simpleMetadataObject (metadata) {
    return {
      artist: metadata.artist[0],
      album: metadata.album,
      title: metadata.title,
      year: metadata.year,
      track: metadata.track.no,
      genre: metadata.genre[0],
      duration: metadata.duration
    }
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
