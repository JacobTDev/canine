const spawnMenu = document.querySelector("#spawn-container");
const spawnShepherd = document.querySelector("#spawn-shepherd");
const spawnHusky = document.querySelector("#spawn-husky");
const spawnRetriever = document.querySelector("#spawn-retriever");


window.addEventListener("message", (e) => {
  if (e.data.open) {
    spawnMenu.style.display = "block";
    console.log("hiwdawdawjdk hawd jawd hadwjaw dhawj dk")
  } else {
    actuallyCloseMenus();
  }
});

document.addEventListener("keydown", (e) => {
  if (e.code == "Escape") {
    tellNuiToCloseMenus()
  }
});



spawnShepherd.addEventListener("click", e => {
  const name = document.getElementById("shepherd-name").value;
  document.getElementById("shepherd-name").value = "";
  sendSpawnCanine(name, "shepherd");
})

spawnHusky.addEventListener("click", e => {
  const name = document.getElementById("husky-name").value;
  document.getElementById("husky-name").value = "";
  sendSpawnCanine(name, "husky");
})

spawnRetriever.addEventListener("click", e => {
  const name = document.getElementById("retriever-name").value;
  document.getElementById("retriever-name").value = "";
  sendSpawnCanine(name, "retriever");
})


function actuallyCloseMenus() {
  spawnMenu.style.display = "none";
}

function tellNuiToCloseMenus() {
  postToNUI("nui:canine:closemenu", {close: true});
}

function sendSpawnCanine(name, canineType) {
  postToNUI("nui:canine:spawncanine", {name, canineType})
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
