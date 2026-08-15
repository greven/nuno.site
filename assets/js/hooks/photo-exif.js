import exifr from 'exifr';

// Reads EXIF metadata (capture date and camera) from photos as they are
// selected or dropped, then fills the matching entry's form inputs directly
// in the DOM. The values are picked up by the regular form submission when
// the photos are processed, so no server-side handling is needed.
//
// The dropzone carries `phx-drop-target` with the upload ref, which is also
// the id of the LiveView file input.
export const PhotoExif = {
  mounted() {
    const uploadRef = this.el.getAttribute('phx-drop-target');
    this.fileInput = document.getElementById(uploadRef);

    this.onFilesSelected = this.onFilesSelected.bind(this);
    this.onFilesDropped = this.onFilesDropped.bind(this);

    this.fileInput?.addEventListener('change', this.onFilesSelected);
    this.el.addEventListener('drop', this.onFilesDropped);

    // A batch of files can be seen by both events (e.g. LiveView re-dispatches
    // an input event after a drop), so only read each file once.
    this.seenFiles = new Set();
    this.observers = [];
  },

  destroyed() {
    this.fileInput?.removeEventListener('change', this.onFilesSelected);
    this.el.removeEventListener('drop', this.onFilesDropped);
    this.observers.forEach((observer) => observer.disconnect());
  },

  onFilesSelected(event) {
    this.handleFiles(Array.from(event.target.files || []));
  },

  onFilesDropped(event) {
    // LiveView clears the file input for drag-and-drop, so the dropped files
    // are only available on the event's dataTransfer.
    this.handleFiles(Array.from(event.dataTransfer?.files || []));
  },

  handleFiles(files) {
    files.forEach((file) => {
      if (this.seenFiles.has(file)) return;
      this.seenFiles.add(file);
      this.readExif(file);
    });
  },

  async readExif(file) {
    let data;
    try {
      data = await exifr.parse(file, ['Make', 'Model', 'DateTimeOriginal']);
    } catch (error) {
      // Files without EXIF (PNG, GIF, screenshots, ...) raise here; nothing
      // to fill in, and the fields can be filled by hand instead.
      console.warn('[PhotoExif] no EXIF for', file.name, error);
      return;
    }

    this.fillEntry(file.name, {
      date: toIsoDate(data.DateTimeOriginal),
      camera: cameraName(data.Make, data.Model),
    });
  },

  // The entry card is rendered by LiveView once the upload starts, so wait
  // for it (if needed) before filling its inputs.
  fillEntry(clientName, values) {
    const form = this.fileInput?.form;
    if (!form) return;

    if (this.applyToEntry(form, clientName, values)) return;

    const observer = new MutationObserver(() => {
      if (this.applyToEntry(form, clientName, values)) observer.disconnect();
    });

    this.observers.push(observer);
    observer.observe(form, { childList: true, subtree: true });
    setTimeout(() => {
      observer.disconnect();
      this.observers = this.observers.filter((o) => o !== observer);
    }, 10_000);
  },

  applyToEntry(form, clientName, values) {
    const entry = this.findEntryCard(form, clientName);
    if (!entry) return false;

    const set = (suffix, value) => {
      if (!value) return;
      const input = entry.querySelector(`[id$="-${suffix}"]`);
      // Never overwrite a value the user typed.
      if (input && !input.value) input.value = value;
    };

    set('date', values.date);
    set('camera', values.camera);
    return true;
  },

  findEntryCard(form, clientName) {
    return Array.from(form.querySelectorAll('[id^="photo-entry-"]')).find((card) => {
      const nameEl = card.querySelector('p.truncate');
      return nameEl && nameEl.textContent.trim() === clientName;
    });
  },
};

// EXIF stores dates as "2023:05:14 15:32:10" (colon-separated); exifr may
// also hand back a Date. Only the calendar date is kept, from the camera's
// local wall-clock time.
function toIsoDate(value) {
  if (!value) return '';

  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return '';
    const y = value.getFullYear();
    const m = String(value.getMonth() + 1).padStart(2, '0');
    const d = String(value.getDate()).padStart(2, '0');
    return `${y}-${m}-${d}`;
  }

  const match = String(value).match(/^(\d{4})[:/-](\d{1,2})[:/-](\d{1,2})/);
  return match ? `${match[1]}-${match[2].padStart(2, '0')}-${match[3].padStart(2, '0')}` : '';
}

// Combine the EXIF make and model, skipping a make duplicated at the start of
// the model (e.g. make "Canon" and model "Canon EOS 5D" -> "Canon EOS 5D").
function cameraName(make, model) {
  const makeStr = String(make ?? '').trim();
  const modelStr = String(model ?? '').trim();
  if (!makeStr) return modelStr;
  if (!modelStr) return makeStr;
  return modelStr.toLowerCase().startsWith(makeStr.toLowerCase())
    ? modelStr
    : `${makeStr} ${modelStr}`;
}
