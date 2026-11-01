const ADJECTIVES = [
  "Sneaky", "Quiet", "Rusty", "Lucky", "Sleepy", "Jumpy", "Bold", "Cosmic",
  "Salty", "Wily", "Brave", "Swift", "Clever", "Fierce", "Noble", "Shy",
  "Shadow", "Mighty", "Zesty", "Chill", "Breezy", "Golden", "Silent", "Daring",
  "Spicy", "Frosty", "Hyper", "Curious", "Sunny", "Electric"
];

const ANIMALS = [
  "Fox", "Otter", "Panda", "Moth", "Crow", "Gecko", "Lynx", "Yak",
  "Newt", "Hare", "Falcon", "Badger", "Wolf", "Raven", "Koala", "Tiger",
  "Hawk", "Viper", "Beaver", "Ferret", "Cheetah", "Panther", "Owl", "Bison",
  "Eagle", "Dolphin", "Bear", "Penguin", "Jaguar", "Raccoon"
];

export const PLAYER_COLORS = [
  "#9a0f28", // Crimson
  "#c2410c", // Orange
  "#a16207", // Amber
  "#4d7c0f", // Green
  "#0f766e", // Teal
  "#1d4ed8", // Blue
  "#6d28d9", // Purple
  "#be185d", // Pink
];

export function generateRandomName(): string {
  const adj = ADJECTIVES[Math.floor(Math.random() * ADJECTIVES.length)];
  const ani = ANIMALS[Math.floor(Math.random() * ANIMALS.length)];
  const num = Math.floor(10 + Math.random() * 90);
  return `${adj} ${ani} ${num}`;
}

export function generateRandomColor(): string {
  return PLAYER_COLORS[Math.floor(Math.random() * PLAYER_COLORS.length)];
}
