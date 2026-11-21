import React, { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { keyboardMarks, isWord, scoreGuess, MAX_GUESSES, WORD_LENGTH } from './rules';
import { loadWordPuzzle, saveWordPuzzle } from './puzzles';

const KEYS = ['QWERTYUIOP'.split(''), 'ASDFGHJKL'.split(''), ['Enter', ...'ZXCVBNM', 'Delete']];
const MARK_LABEL = { exact: 'correct spot', present: 'different spot', absent: 'no remaining match' };

export default function WordPuzzleScreen(props) {
  return <PuzzleSession key={props.occurrenceId} {...props} />;
}

function PuzzleSession({ occurrenceId, alarmTime, onSolved }) {
  const [puzzle, setPuzzle] = useState(null);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState('');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);
  const [completionError, setCompletionError] = useState(false);
  const busy = useRef(false);
  const { width, height } = useWindowDimensions();
  const tile = Math.min(53, Math.floor((width - 64) / 5), Math.max(34, Math.floor((height - 315) / 6)));
  const solved = Boolean(puzzle?.guesses.includes(puzzle.answer));
  const exhausted = puzzle?.guesses.length === MAX_GUESSES && !solved;

  useEffect(() => {
    let mounted = true;
    async function load() {
      try {
        const saved = await loadWordPuzzle(occurrenceId);
        if (mounted) {
          setPuzzle(saved);
          if (!saved) setMessage('This alarm has no prepared word puzzle.');
        }
      } catch {
        if (mounted) setMessage('Could not load the saved puzzle.');
      } finally {
        if (mounted) setLoading(false);
      }
    }
    load();
    return () => { mounted = false; };
  }, [occurrenceId]);

  async function reportSolved() {
    setCompletionError(false);
    try {
      await onSolved(occurrenceId);
    } catch {
      setCompletionError(true);
    }
  }

  const completion = useRef(onSolved);
  completion.current = onSolved;
  useEffect(() => {
    if (solved) {
      Promise.resolve().then(() => completion.current(occurrenceId)).catch(() => setCompletionError(true));
    }
  }, [solved, occurrenceId]);

  async function persist(guesses) {
    if (busy.current) return;
    busy.current = true;
    setSaving(true);
    try {
      const next = { ...puzzle, guesses };
      await saveWordPuzzle(next);
      setPuzzle(next);
      setDraft('');
      setMessage('');
    } catch {
      setMessage('Could not save your progress. Try again.');
    } finally {
      busy.current = false;
      setSaving(false);
    }
  }

  function handleKey(key) {
    if (busy.current || solved || exhausted) return;
    if (key === 'Enter') {
      if (draft.length !== WORD_LENGTH) {
        setMessage('Enter five letters.');
      } else if (!isWord(draft)) {
        setMessage('That word is not in the puzzle dictionary.');
      } else {
        void persist([...puzzle.guesses, draft]);
      }
      return;
    }
    setMessage('');
    setDraft((value) => key === 'Delete' ? value.slice(0, -1) : (value + key.toLowerCase()).slice(0, WORD_LENGTH));
  }

  const marks = puzzle ? keyboardMarks(puzzle.guesses, puzzle.answer) : {};
  const status = message || (exhausted ? 'Six guesses used. Try the same word on a fresh board.' : '');

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.header}>
          <Text style={styles.brand}>SnoozeLose</Text>
          {alarmTime ? <Text style={styles.time}>{alarmTime}</Text> : null}
        </View>
        <Text accessibilityRole="header" style={styles.title}>{alarmTime ? 'Solve to stop alarm' : 'Guess the word'}</Text>
        <Text style={styles.instructions}>Find the five-letter word in six guesses.</Text>
        {loading && <ActivityIndicator color="#6A5ACD" style={styles.loading} />}
        {!puzzle && !loading && <Text accessibilityRole="alert" style={styles.status}>{message}</Text>}
        {puzzle && (
          <>
            <View style={styles.board}>
              {Array.from({ length: MAX_GUESSES }, (_, row) => {
                const guess = puzzle.guesses[row];
                const rowMarks = guess ? scoreGuess(guess, puzzle.answer) : [];
                const letters = guess ?? (row === puzzle.guesses.length && !solved ? draft : '');
                return (
                  <View key={row} style={styles.tiles}>
                    {Array.from({ length: WORD_LENGTH }, (_, col) => {
                      const mark = rowMarks[col];
                      const letter = letters[col]?.toUpperCase();
                      return (
                        <View
                          key={col}
                          accessible
                          accessibilityLabel={letter ? `${letter}, ${MARK_LABEL[mark] ?? 'unsubmitted'}` : 'Empty tile'}
                          style={[styles.tile, { width: tile, height: tile }, letter && styles.filled, styles[mark]]}
                        >
                          <Text style={[styles.letter, mark && mark !== 'present' && styles.markedLetter]}>{letter}</Text>
                        </View>
                      );
                    })}
                  </View>
                );
              })}
            </View>
            <View style={styles.feedback}>
              <Text accessibilityLiveRegion="polite" style={styles.status}>
                {solved ? (completionError ? 'Puzzle solved. Could not finish the alarm.' : 'Puzzle solved!') : status}
              </Text>
              {exhausted && <Action label="Try again" disabled={saving} onPress={() => persist([])} />}
              {completionError && <Action label="Finish alarm" onPress={reportSolved} />}
            </View>
            <View style={styles.keyboard}>
              {KEYS.map((row) => (
                <View style={styles.keyRow} key={row[0]}>
                  {row.map((key) => {
                    const mark = marks[key.toLowerCase()];
                    const wide = key.length > 1;
                    return (
                      <Pressable
                        key={key}
                        accessibilityRole="button"
                        accessibilityLabel={mark ? `${key}, ${MARK_LABEL[mark]}` : key}
                        disabled={saving || solved || exhausted}
                        onPress={() => handleKey(key)}
                        style={({ pressed }) => [styles.key, wide && styles.wideKey, styles[mark], pressed && styles.pressed]}
                      >
                        <Text style={[styles.keyText, mark === 'present' && styles.darkKeyText, wide && styles.wideText]}>{key === 'Delete' ? '⌫' : key}</Text>
                      </Pressable>
                    );
                  })}
                </View>
              ))}
            </View>
          </>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function Action({ label, onPress, disabled }) {
  return (
    <Pressable accessibilityRole="button" style={styles.action} onPress={onPress} disabled={disabled}>
      <Text style={styles.keyText}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#E0FFFF' },
  content: { width: '100%', maxWidth: 460, alignSelf: 'center', paddingHorizontal: 14, paddingVertical: 14 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 },
  brand: { color: '#46348F', fontWeight: '800', fontSize: 16 },
  time: { color: '#263555', fontSize: 15, fontWeight: '700' },
  title: { color: '#1D2141', fontSize: 29, fontWeight: '800', textAlign: 'center' },
  instructions: { textAlign: 'center', color: '#384565', marginTop: 5, marginBottom: 16 },
  loading: { margin: 24 },
  board: { gap: 5, alignItems: 'center' },
  tiles: { flexDirection: 'row', gap: 5 },
  tile: { borderWidth: 1, borderColor: '#8998AB', borderRadius: 8, backgroundColor: '#F6FFFF', alignItems: 'center', justifyContent: 'center' },
  filled: { borderColor: '#6A5ACD', borderWidth: 2 },
  letter: { color: '#1D2141', fontSize: 24, fontWeight: '800' },
  markedLetter: { color: '#FFFFFF' },
  exact: { backgroundColor: '#22734E', borderColor: '#22734E' },
  present: { backgroundColor: '#F4CA59', borderColor: '#A98118' },
  absent: { backgroundColor: '#55586B', borderColor: '#55586B' },
  feedback: { minHeight: 40, justifyContent: 'center', alignItems: 'center', paddingVertical: 4 },
  status: { color: '#29234E', textAlign: 'center', fontWeight: '600' },
  action: { backgroundColor: '#6A5ACD', borderRadius: 10, padding: 12, marginTop: 6 },
  keyboard: { gap: 5 },
  keyRow: { flexDirection: 'row', gap: 3, justifyContent: 'center' },
  key: { flex: 1, maxWidth: 42, minHeight: 46, backgroundColor: '#6A5ACD', borderRadius: 7, justifyContent: 'center', alignItems: 'center' },
  wideKey: { flex: 1.45, maxWidth: 55 },
  keyText: { color: '#FFFFFF', fontSize: 15, fontWeight: '800' },
  darkKeyText: { color: '#1D2141' },
  wideText: { fontSize: 12 },
  pressed: { opacity: 0.72 },
});
