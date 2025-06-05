import Dropzone from "dropzone";

import { csrfToken } from "../../lib/request";
import { replaceSelection } from "./selection";

type UploadResponse = { error: string } | { embed: string };

function uploadBanner(file: File) {
  return '[Uploading "' + file.name + '"...]';
}

function startUpload(elem: HTMLTextAreaElement, file: File) {
  replaceSelection(elem, uploadBanner(file) + "\n", "", "");
}

function uploadError(response: UploadResponse) {
  if (typeof response === "object" && "error" in response && response.error) {
    alert("There was an error uploading the image: " + response.error);
  }
}

function finishUpload(
  elem: HTMLTextAreaElement,
  file: File,
  response: UploadResponse
) {
  uploadError(response);
  if (response && "embed" in response && response.embed) {
    elem.value = elem.value.replace(uploadBanner(file) + "\n", response.embed);
  }
}

function failedUpload(
  elem: HTMLTextAreaElement,
  file: File,
  response: UploadResponse
) {
  uploadError(response);
  elem.value = elem.value.replace(uploadBanner(file), "");
}

function uploadImageFile(
  textarea: HTMLTextAreaElement,
  file: File,
  callback?: () => void
) {
  const reader = new FileReader();
  reader.onload = async function () {
    startUpload(textarea, file);
    const formData = new FormData();
    formData.append("upload[file]", file);

    await fetch("/uploads.json", {
      method: "post",
      body: formData,
      headers: {
        "X-CSRF-Token": csrfToken()
      }
    })
      .then((response) => response.json())
      .then((json: UploadResponse) => finishUpload(textarea, file, json));
    if (callback) {
      callback();
    }
  };
  reader.readAsDataURL(file);
}

export function uploadImage(textarea: HTMLTextAreaElement) {
  const fileInput = document.createElement("input");
  fileInput.type = "file";
  fileInput.accept = "image/gif, image/png, image/jpeg, image/webp";
  fileInput.style.display = "none";

  textarea.parentNode.insertBefore(fileInput, textarea);
  fileInput.addEventListener(
    "change",
    function () {
      const file = fileInput.files[0];
      uploadImageFile(textarea, file, () => {
        fileInput.remove();
      });
    },
    false
  );
  fileInput.click();
}

export function bindUploads(elem: HTMLTextAreaElement) {
  const dropzone = new Dropzone(elem, {
    url: "/uploads.json",
    paramName: "upload[file]",
    headers: { "X-CSRF-Token": csrfToken() },
    acceptedFiles: "image/jpeg,image/png,image/gif,image/tiff,image/webp",
    clickable: false,
    createImageThumbnails: false
  });

  dropzone.on("addedfile", (file) => startUpload(elem, file));
  dropzone.on("success", (file) =>
    finishUpload(
      elem,
      file,
      JSON.parse(file.xhr.responseText) as UploadResponse
    )
  );
  dropzone.on("error", (file, message: UploadResponse) =>
    failedUpload(elem, file, message)
  );

  elem.addEventListener("paste", (evt: ClipboardEvent) => {
    const items = evt.clipboardData.items;
    for (const i in items) {
      const item = items[i];
      if (item.kind == "file" && item.type.match(/^image\//)) {
        uploadImageFile(elem, item.getAsFile());
      }
    }
  });
}
