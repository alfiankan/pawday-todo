const storageKey = "cat-kingdom-save-v1";

const buildings = [
  {
    id: "townhall",
    name: "Townhall",
    role: "Unlocks higher upgrades",
    baseCost: { fish: 18, wood: 12, gems: 0 },
  },
  {
    id: "bakery",
    name: "Pancake Bakery",
    role: "Serves hungry cats",
    baseCost: { fish: 12, wood: 8, gems: 0 },
  },
  {
    id: "inn",
    name: "Nap Inn",
    role: "Keeps heroes rested",
    baseCost: { fish: 10, wood: 14, gems: 0 },
  },
  {
    id: "workshop",
    name: "Yarn Workshop",
    role: "Improves item finds",
    baseCost: { fish: 14, wood: 18, gems: 1 },
  },
];

const heroes = [
  {
    id: "miso",
    name: "Miso",
    title: "Tiny Knight",
    color: 0xef746f,
    baseCost: { fish: 16, wood: 6, gems: 0 },
  },
  {
    id: "plum",
    name: "Plum",
    title: "Moon Mage",
    color: 0x8267c7,
    baseCost: { fish: 12, wood: 10, gems: 1 },
  },
  {
    id: "biscuit",
    name: "Biscuit",
    title: "Shield Baker",
    color: 0xe5a93d,
    baseCost: { fish: 20, wood: 14, gems: 1 },
  },
];

const defaultState = {
  fish: 30,
  wood: 24,
  gems: 2,
  day: 1,
  buildings: {
    townhall: 1,
    bakery: 1,
    inn: 1,
    workshop: 1,
  },
  heroes: {
    miso: 1,
    plum: 1,
    biscuit: 1,
  },
  log: [
    "The first kittens arrive at Cat Kingdom.",
    "Townhall bells ring for a soft little morning.",
  ],
};

let state = loadState();
let gameScene;

const fishCount = document.querySelector("#fishCount");
const woodCount = document.querySelector("#woodCount");
const gemCount = document.querySelector("#gemCount");
const townhallTitle = document.querySelector("#townhallTitle");
const buildingList = document.querySelector("#buildingList");
const heroList = document.querySelector("#heroList");
const logList = document.querySelector("#logList");
const battleNote = document.querySelector("#battleNote");
const collectButton = document.querySelector("#collectButton");
const forageButton = document.querySelector("#forageButton");
const battleButton = document.querySelector("#battleButton");

function loadState() {
  try {
    const saved = JSON.parse(localStorage.getItem(storageKey));
    return saved ? mergeState(saved) : structuredClone(defaultState);
  } catch {
    return structuredClone(defaultState);
  }
}

function mergeState(saved) {
  return {
    ...structuredClone(defaultState),
    ...saved,
    buildings: { ...defaultState.buildings, ...saved.buildings },
    heroes: { ...defaultState.heroes, ...saved.heroes },
    log: Array.isArray(saved.log) ? saved.log.slice(0, 6) : defaultState.log,
  };
}

function saveState() {
  localStorage.setItem(storageKey, JSON.stringify(state));
}

function getCost(item, level) {
  const multiplier = level;
  return {
    fish: Math.ceil(item.baseCost.fish * multiplier * 1.15),
    wood: Math.ceil(item.baseCost.wood * multiplier * 1.12),
    gems: Math.ceil(item.baseCost.gems * multiplier),
  };
}

function canPay(cost) {
  return state.fish >= cost.fish && state.wood >= cost.wood && state.gems >= cost.gems;
}

function pay(cost) {
  state.fish -= cost.fish;
  state.wood -= cost.wood;
  state.gems -= cost.gems;
}

function formatCost(cost) {
  const parts = [];
  if (cost.fish) parts.push(`${cost.fish} fish`);
  if (cost.wood) parts.push(`${cost.wood} wood`);
  if (cost.gems) parts.push(`${cost.gems} gem${cost.gems === 1 ? "" : "s"}`);
  return parts.join(", ");
}

function addLog(message) {
  state.log.unshift(message);
  state.log = state.log.slice(0, 6);
}

function kingdomPower() {
  const heroPower = heroes.reduce((total, hero) => total + state.heroes[hero.id] * 6, 0);
  const buildingPower = buildings.reduce(
    (total, building) => total + state.buildings[building.id] * 2,
    0,
  );
  return heroPower + buildingPower;
}

function upgradeBuilding(id) {
  const building = buildings.find((item) => item.id === id);
  const level = state.buildings[id];
  const townhallLevel = state.buildings.townhall;

  if (id !== "townhall" && level >= townhallLevel) {
    addLog(`${building.name} needs Townhall Lv. ${level + 1} first.`);
    render();
    return;
  }

  const cost = getCost(building, level);
  if (!canPay(cost)) {
    addLog(`Need ${formatCost(cost)} for ${building.name}.`);
    render();
    return;
  }

  pay(cost);
  state.buildings[id] += 1;
  addLog(`${building.name} upgraded to Lv. ${state.buildings[id]}.`);
  persistAndRender(true);
}

function upgradeHero(id) {
  const hero = heroes.find((item) => item.id === id);
  const level = state.heroes[id];
  const townhallLevel = state.buildings.townhall;

  if (level >= townhallLevel + 1) {
    addLog(`${hero.name} needs a stronger Townhall before training more.`);
    render();
    return;
  }

  const cost = getCost(hero, level);
  if (!canPay(cost)) {
    addLog(`Need ${formatCost(cost)} to train ${hero.name}.`);
    render();
    return;
  }

  pay(cost);
  state.heroes[id] += 1;
  addLog(`${hero.name} becomes ${hero.title} Lv. ${state.heroes[id]}.`);
  persistAndRender(true);
}

function gatherItems() {
  const bakery = state.buildings.bakery;
  const workshop = state.buildings.workshop;
  const fish = 8 + bakery * 5;
  const wood = 6 + workshop * 4;
  const gems = Math.random() < 0.22 + workshop * 0.03 ? 1 : 0;

  state.fish += fish;
  state.wood += wood;
  state.gems += gems;
  state.day += 1;
  addLog(`Day ${state.day}: collected ${fish} fish, ${wood} yarnwood${gems ? ", and 1 moon gem" : ""}.`);
  persistAndRender(true);
}

function forage() {
  const workshop = state.buildings.workshop;
  const roll = Phaser.Math.Between(1, 100);
  const fish = Phaser.Math.Between(5, 11) + workshop * 2;
  const wood = Phaser.Math.Between(7, 13) + workshop * 3;

  state.fish += fish;
  state.wood += wood;
  if (roll > 74) {
    state.gems += 1;
    addLog(`A shiny basket held ${fish} fish, ${wood} yarnwood, and 1 moon gem.`);
  } else {
    addLog(`Scouts found ${fish} fish and ${wood} yarnwood near the clover hills.`);
  }
  persistAndRender(true);
}

function battle() {
  const power = kingdomPower();
  const enemyPower = 24 + state.day * 4 + Phaser.Math.Between(0, 18);
  const won = power + Phaser.Math.Between(0, 24) >= enemyPower;

  if (won) {
    const fish = 18 + state.buildings.townhall * 5;
    const wood = 12 + state.buildings.inn * 4;
    const gems = enemyPower > 60 ? 2 : 1;
    state.fish += fish;
    state.wood += wood;
    state.gems += gems;
    addLog(`Victory! Cat heroes won ${fish} fish, ${wood} yarnwood, and ${gems} moon gem${gems === 1 ? "" : "s"}.`);
    gameScene?.showBattleBurst(true);
  } else {
    const fishLoss = Math.min(state.fish, 8);
    state.fish -= fishLoss;
    addLog(`The snack bandits escaped. The kingdom lost ${fishLoss} fish.`);
    gameScene?.showBattleBurst(false);
  }

  persistAndRender(true);
}

function persistAndRender(refreshScene = false) {
  saveState();
  render();
  if (refreshScene) gameScene?.refreshKingdom();
}

function render() {
  fishCount.textContent = `${state.fish} fish`;
  woodCount.textContent = `${state.wood} yarnwood`;
  gemCount.textContent = `${state.gems} moon gem${state.gems === 1 ? "" : "s"}`;
  townhallTitle.textContent = `Townhall Lv. ${state.buildings.townhall}`;

  renderBuildings();
  renderHeroes();
  renderLog();

  const power = kingdomPower();
  battleNote.textContent = `Kingdom power ${power}. Battles reward rare moon gems for hero training.`;
}

function renderBuildings() {
  buildingList.innerHTML = "";

  buildings.forEach((building) => {
    const level = state.buildings[building.id];
    const cost = getCost(building, level);
    const locked = building.id !== "townhall" && level >= state.buildings.townhall;
    const card = document.createElement("article");
    card.className = "upgrade-card";
    card.innerHTML = `
      <div>
        <p class="card-name">${building.name} Lv. ${level}</p>
        <p class="card-detail">${building.role}<br>Next: ${formatCost(cost)}</p>
      </div>
    `;

    const button = document.createElement("button");
    button.type = "button";
    button.textContent = locked ? "Locked" : "Upgrade";
    button.disabled = locked || !canPay(cost);
    button.addEventListener("click", () => upgradeBuilding(building.id));
    card.append(button);
    buildingList.append(card);
  });
}

function renderHeroes() {
  heroList.innerHTML = "";

  heroes.forEach((hero) => {
    const level = state.heroes[hero.id];
    const cost = getCost(hero, level);
    const locked = level >= state.buildings.townhall + 1;
    const card = document.createElement("article");
    card.className = "hero-card";
    card.innerHTML = `
      <div>
        <p class="card-name">${hero.name} Lv. ${level}</p>
        <p class="card-detail">${hero.title}<br>Train: ${formatCost(cost)}</p>
      </div>
    `;

    const button = document.createElement("button");
    button.type = "button";
    button.textContent = locked ? "Townhall" : "Train";
    button.disabled = locked || !canPay(cost);
    button.addEventListener("click", () => upgradeHero(hero.id));
    card.append(button);
    heroList.append(card);
  });
}

function renderLog() {
  logList.innerHTML = "";
  state.log.forEach((entry) => {
    const item = document.createElement("li");
    item.textContent = entry;
    logList.append(item);
  });
}

class CatKingdomScene extends Phaser.Scene {
  constructor() {
    super("CatKingdomScene");
    this.buildingSprites = {};
    this.heroSprites = {};
  }

  create() {
    gameScene = this;
    this.createTextures();
    this.buildWorld();
    this.refreshKingdom();
  }

  createTextures() {
    this.makeCatTexture("cat-miso", 0xef746f);
    this.makeCatTexture("cat-plum", 0x8267c7);
    this.makeCatTexture("cat-biscuit", 0xe5a93d);
  }

  makeCatTexture(key, color) {
    const g = this.make.graphics({ x: 0, y: 0, add: false });
    g.fillStyle(color, 1);
    g.lineStyle(5, 0x2b2730, 1);
    g.fillTriangle(18, 30, 30, 4, 44, 30);
    g.strokeTriangle(18, 30, 30, 4, 44, 30);
    g.fillTriangle(54, 30, 68, 4, 80, 30);
    g.strokeTriangle(54, 30, 68, 4, 80, 30);
    g.fillRoundedRect(12, 20, 76, 66, 24);
    g.strokeRoundedRect(12, 20, 76, 66, 24);
    g.fillStyle(0x2b2730, 1);
    g.fillCircle(36, 50, 4);
    g.fillCircle(64, 50, 4);
    g.fillStyle(0xffffff, 1);
    g.fillCircle(37, 48, 1.5);
    g.fillCircle(65, 48, 1.5);
    g.fillStyle(0xd65a66, 1);
    g.fillCircle(50, 62, 4);
    g.generateTexture(key, 100, 96);
    g.destroy();
  }

  buildWorld() {
    this.add.rectangle(480, 360, 960, 720, 0xbfe7d4);
    this.add.rectangle(480, 596, 960, 248, 0x83c88f);
    this.add.ellipse(178, 620, 320, 72, 0x6ebc7b, 0.45);
    this.add.ellipse(680, 620, 430, 82, 0x6ebc7b, 0.45);
    this.add.circle(112, 106, 46, 0xffd66f);

    for (let i = 0; i < 24; i += 1) {
      const x = Phaser.Math.Between(30, 930);
      const y = Phaser.Math.Between(120, 330);
      this.add.circle(x, y, Phaser.Math.Between(2, 4), 0xffffff, 0.7);
    }

    this.drawBuilding("townhall", 468, 298, 178, 172, 0xffcf73);
    this.drawBuilding("bakery", 218, 430, 150, 120, 0xff9f85);
    this.drawBuilding("inn", 716, 426, 154, 124, 0x8fc5f2);
    this.drawBuilding("workshop", 470, 504, 150, 112, 0xc8a0e8);

    const heroPositions = [
      ["miso", 302, 595, "cat-miso"],
      ["plum", 460, 604, "cat-plum"],
      ["biscuit", 620, 594, "cat-biscuit"],
    ];

    heroPositions.forEach(([id, x, y, texture], index) => {
      const sprite = this.add.image(x, y, texture).setInteractive({ useHandCursor: true });
      sprite.setScale(0.76);
      this.heroSprites[id] = sprite;
      this.tweens.add({
        targets: sprite,
        y: y - 8,
        duration: 1200 + index * 140,
        ease: "Sine.inOut",
        yoyo: true,
        repeat: -1,
      });
      sprite.on("pointerdown", () => upgradeHero(id));
    });

    this.add.text(22, 22, "Click cats to train. Click buildings to upgrade.", {
      color: "#2b2730",
      fontFamily: "Inter, Arial, sans-serif",
      fontSize: "18px",
      fontStyle: "700",
      backgroundColor: "rgba(255, 250, 242, 0.72)",
      padding: { x: 12, y: 8 },
    });
  }

  drawBuilding(id, x, y, width, height, color) {
    const group = this.add.container(x, y);
    const body = this.add.rectangle(0, height * 0.12, width, height, color);
    const roof = this.add.triangle(0, -height * 0.62, -width * 0.62, 0, width * 0.62, 0, 0, 0xe07a5f);
    const door = this.add.rectangle(0, height * 0.38, width * 0.24, height * 0.35, 0x6d4a39);
    const windowLeft = this.add.rectangle(-width * 0.28, height * 0.08, 28, 28, 0xfff7c8);
    const windowRight = this.add.rectangle(width * 0.28, height * 0.08, 28, 28, 0xfff7c8);
    const sign = this.add.text(0, height * 0.66, "", {
      color: "#2b2730",
      fontFamily: "Inter, Arial, sans-serif",
      fontSize: "18px",
      fontStyle: "900",
    }).setOrigin(0.5);

    [body, roof, door, windowLeft, windowRight].forEach((shape) => {
      shape.setStrokeStyle(5, 0x2b2730);
    });

    group.add([body, roof, door, windowLeft, windowRight, sign]);
    group.setSize(width, height + 44);
    group.setInteractive({ useHandCursor: true });
    group.on("pointerdown", () => upgradeBuilding(id));

    this.buildingSprites[id] = { group, sign, body, roof };
  }

  refreshKingdom() {
    Object.entries(this.buildingSprites).forEach(([id, sprite]) => {
      const level = state.buildings[id];
      sprite.sign.setText(`Lv. ${level}`);
      sprite.group.setScale(1 + Math.min(level - 1, 6) * 0.045);
    });

    Object.entries(this.heroSprites).forEach(([id, sprite]) => {
      const level = state.heroes[id];
      sprite.setScale(0.76 + Math.min(level - 1, 8) * 0.035);
    });
  }

  showBattleBurst(won) {
    const text = this.add.text(480, 140, won ? "VICTORY!" : "TRY AGAIN!", {
      color: won ? "#2f7155" : "#c54a58",
      fontFamily: "Inter, Arial, sans-serif",
      fontSize: "44px",
      fontStyle: "900",
      stroke: "#fffaf2",
      strokeThickness: 8,
    }).setOrigin(0.5);

    this.tweens.add({
      targets: text,
      y: 96,
      alpha: 0,
      duration: 1100,
      ease: "Cubic.out",
      onComplete: () => text.destroy(),
    });
  }
}

function bootGame() {
  if (!window.Phaser) {
    document.querySelector("#game").innerHTML =
      '<div class="battle-note">Phaser could not load. Check your connection and reload Cat Kingdom.</div>';
    return;
  }

  new Phaser.Game({
    type: Phaser.AUTO,
    parent: "game",
    backgroundColor: "#bfe7d4",
    scale: {
      mode: Phaser.Scale.FIT,
      autoCenter: Phaser.Scale.CENTER_BOTH,
      width: 960,
      height: 720,
    },
    scene: CatKingdomScene,
  });
}

collectButton.addEventListener("click", gatherItems);
forageButton.addEventListener("click", forage);
battleButton.addEventListener("click", battle);

render();
bootGame();
