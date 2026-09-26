export type Suit = 'Spades' | 'Hearts' | 'Clubs' | 'Diamonds';
export type Rank =
  | '3'
  | '4'
  | '5'
  | '6'
  | '7'
  | '8'
  | '9'
  | '10'
  | 'J'
  | 'Q'
  | 'K'
  | 'A'
  | '2'
  | 'BlackWhiteJoker'
  | 'RedJoker';

export type HandType = 'single' | 'pair' | 'triple' | 'four' | 'straight';

export type Card = {
  id: string;
  suit: Suit;
  rank: Rank;
  value: number;
};

export const cardOrder: Record<Rank, number> = {
  '3': 1,
  '4': 2,
  '5': 3,
  '6': 4,
  '7': 5,
  '8': 6,
  '9': 7,
  '10': 8,
  J: 9,
  Q: 10,
  K: 11,
  A: 12,
  '2': 13,
  BlackWhiteJoker: 14,
  RedJoker: 15
};

export function generateDeck(): Card[] {
  const suits: Suit[] = ['Spades', 'Hearts', 'Clubs', 'Diamonds'];
  const ranks: Rank[] = ['3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A', '2'];

  const cards: Card[] = [];

  for (const suit of suits) {
    for (const rank of ranks) {
      cards.push({
        id: `${rank}-${suit}`,
        suit,
        rank,
        value: cardOrder[rank]
      });
    }
  }

  cards.push(
    { id: 'black-white-joker', suit: 'Spades', rank: 'BlackWhiteJoker', value: cardOrder.BlackWhiteJoker },
    { id: 'red-joker', suit: 'Hearts', rank: 'RedJoker', value: cardOrder.RedJoker }
  );

  return cards;
}

export function sortCards(cards: Card[]): Card[] {
  return [...cards].sort((a, b) => a.value - b.value);
}

export function getHandType(cards: Card[]): HandType {
  if (cards.length === 0) {
    throw new Error('Cannot determine hand type for an empty hand.');
  }

  const counts = new Map<number, number>();
  for (const card of cards) {
    counts.set(card.value, (counts.get(card.value) ?? 0) + 1);
  }

  const groups = [...counts.values()].sort((a, b) => a - b);

  if (groups.length === 1) {
    if (groups[0] === 1) return 'single';
    if (groups[0] === 2) return 'pair';
    if (groups[0] === 3) return 'triple';
    if (groups[0] === 4) return 'four';
  }

  if (cards.length >= 5 && isStraight(cards)) {
    return 'straight';
  }

  throw new Error('Unsupported or invalid hand shape.');
}

export function isStraight(cards: Card[]): boolean {
  if (cards.length < 5) {
    return false;
  }

  const uniqueSorted = [...new Set(cards.map((card) => card.value))].sort((a, b) => a - b);
  if (uniqueSorted.length !== cards.length) {
    return false;
  }

  for (let i = 1; i < uniqueSorted.length; i += 1) {
    if (uniqueSorted[i] - uniqueSorted[i - 1] !== 1) {
      return false;
    }
  }

  return true;
}

export function validateMove(cards: Card[]): boolean {
  if (cards.length === 0) return false;

  try {
    getHandType(cards);
    return true;
  } catch {
    return false;
  }
}

export function compareHands(left: Card[], right: Card[]): number {
  const leftType = getHandType(left);
  const rightType = getHandType(right);

  if (leftType === 'four' && rightType !== 'four') return 1;
  if (rightType === 'four' && leftType !== 'four') return -1;

  if (leftType !== rightType || left.length !== right.length) {
    throw new Error('Only identical hand types and sizes can be compared.');
  }

  const leftMax = Math.max(...left.map((card) => card.value));
  const rightMax = Math.max(...right.map((card) => card.value));

  return leftMax - rightMax;
}

export function canBeat(candidate: Card[], current: Card[] | null): boolean {
  if (!current) return validateMove(candidate);

  try {
    return compareHands(candidate, current) > 0;
  } catch {
    return false;
  }
}
