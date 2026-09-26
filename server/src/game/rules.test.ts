import { describe, expect, it } from 'vitest';
import { type Card, type Rank, type Suit, canBeat, compareHands, generateDeck, getHandType, validateMove } from './rules.js';

function makeCard(id: string, rank: string, value: number): Card {
  return {
    id,
    suit: 'Spades' as Suit,
    rank: rank as Rank,
    value
  };
}

describe('Murlan rule engine', () => {
  it('generates a standard deck with 54 cards', () => {
    const deck = generateDeck();
    expect(deck).toHaveLength(54);
    expect(deck.filter((card) => card.rank === 'RedJoker')).toHaveLength(1);
    expect(deck.filter((card) => card.rank === 'BlackWhiteJoker')).toHaveLength(1);
  });

  it('classifies valid singles, pairs, triples, four-of-a-kind and straights', () => {
    expect(getHandType([makeCard('a', '9', 7)])).toBe('single');
    expect(getHandType([makeCard('a', 'Q', 10), makeCard('b', 'Q', 10)])).toBe('pair');
    expect(getHandType([makeCard('a', 'A', 12), makeCard('b', 'A', 12), makeCard('c', 'A', 12)])).toBe('triple');
    expect(
      getHandType([
        makeCard('a', '7', 5),
        makeCard('b', '7', 5),
        makeCard('c', '7', 5),
        makeCard('d', '7', 5)
      ])
    ).toBe('four');

    expect(
      getHandType([
        makeCard('a', '8', 6),
        makeCard('b', '9', 7),
        makeCard('c', '10', 8),
        makeCard('d', 'J', 9),
        makeCard('e', 'Q', 10)
      ])
    ).toBe('straight');
  });

  it('rejects invalid hand shapes', () => {
    expect(() =>
      getHandType([
        makeCard('a', '9', 7),
        makeCard('b', '9', 7),
        makeCard('c', '10', 8),
        makeCard('d', 'Q', 10)
      ])
    ).toThrow();

    expect(
      validateMove([
        makeCard('a', '8', 6),
        makeCard('b', '9', 7),
        makeCard('c', '10', 8),
        makeCard('d', 'J', 9),
        makeCard('e', 'Q', 10)
      ])
    ).toBe(true);

    expect(
      validateMove([
        makeCard('a', '8', 6),
        makeCard('b', '9', 7),
        makeCard('c', '10', 8),
        makeCard('d', 'Q', 10)
      ])
    ).toBe(false);
  });

  it('compares bombs across types and rejects other type or size mismatches', () => {
    const four = [
      makeCard('a', '7', 5),
      makeCard('b', '7', 5),
      makeCard('c', '7', 5),
      makeCard('d', '7', 5)
    ];

    const straight = [
      makeCard('a', '8', 6),
      makeCard('b', '9', 7),
      makeCard('c', '10', 8),
      makeCard('d', 'J', 9),
      makeCard('e', 'Q', 10)
    ];

    expect(compareHands(four, straight)).toBeGreaterThan(0);
    expect(compareHands(straight, four)).toBeLessThan(0);

    const pair = [makeCard('a', 'A', 12), makeCard('b', 'A', 12)];
    const triple = [makeCard('a', '2', 13), makeCard('b', '2', 13), makeCard('c', '2', 13)];
    expect(() => compareHands(triple, pair)).toThrow('identical hand types and sizes');
    expect(canBeat(triple, pair)).toBe(false);
    expect(canBeat(straight, [
      makeCard('a', '8', 6),
      makeCard('b', '9', 7),
      makeCard('c', '10', 8),
      makeCard('d', 'J', 9),
      makeCard('e', 'K', 11),
      makeCard('f', 'Q', 10)
    ])).toBe(false);
  });
});
