function ajaxRequest(url) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('GET', url, true);
    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
          resolve(xhr.responseText);
        } else {
          reject(`Error: ${xhr.status}`);
        }
      }
    };
    xhr.onerror = function () {
      reject('AJAX Request Failed');
    };
    xhr.send();
  });
}

