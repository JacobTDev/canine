const spawnMenu = document.querySelector("#spawn-container");

window.addEventListener("message", (e) => {
  console.log("bitach")
  if (e.data.open) {
    if (e.data.spawned) {
      // Show action menu
    } else {
      spawnMenu.style.display = "block";
      console.log("hiwdawdawjdk hawd jawd hadwjaw dhawj dk")
    }
  } else {
    actuallyCloseMenus();
  }
});

document.addEventListener("keydown", (e) => {
  if (e.code == "Escape") {
    tellNuiToCloseMenus()
  }
});

function actuallyCloseMenus() {
  spawnMenu.style.display = "none";
}

function tellNuiToCloseMenus() {
  postToNUI("closeMenus", {close: true});
}

async function postToNUI(callbackName, obj) {
  await fetch(`https://canine/${callbackName}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(obj),
  });
}
