import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View, useWindowDimensions } from 'react-native';
import PuzzleHeader from './PuzzleHeader';
import { SafeAreaView } from 'react-native-safe-area-context';
import { keyboardMarks, isWord, scoreGuess, MAX_GUESSES } from './rules';
import { loadWordPuzzle, saveWordPuzzle } from './puzzles';

const KEYS = ['QWERTYUIOP'.split(''), 'ASDFGHJKL'.split(''), ['Enter', ...'ZXCVBNM', 'Delete']];
const MARK_LABEL = { exact: 'correct spot', present: 'different spot', absent: 'no remaining match' };

export default function WordPuzzleScreen(props) {
  return <PuzzleSession key={props.occurrenceId} {...props} />;
}

function PuzzleSession({ occurrenceId, alarmTime, onSolved, onWinAnimationComplete }) {
  const [puzzle, setPuzzle] = useState(null);
  const [loading, setLoading] = useState(true);
  const [draft, setDraft] = useState('');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);
  const [completionError, setCompletionError] = useState(false);
  const [alarmStopped, setAlarmStopped] = useState(false);
  const [celebrated, setCelebrated] = useState(false);
  const busy = useRef(false);
  const { width, height } = useWindowDimensions();
  const wordLength = puzzle?.answer.length ?? 5;
  const boardWidth = width - 28 - (wordLength - 1) * 5;
  const tile = Math.min(53, Math.floor(boardWidth / wordLength), Math.max(34, Math.floor((height - 382) / MAX_GUESSES)));
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

  const completion = useRef(onSolved);
  completion.current = onSolved;
  const returnHome = useRef(onWinAnimationComplete);
  returnHome.current = onWinAnimationComplete;
  const reportSolved = useCallback(async () => {
    setCompletionError(false);
    try {
      await completion.current?.(occurrenceId);
      setAlarmStopped(true);
    } catch {
      setCompletionError(true);
    }
  }, [occurrenceId]);

  useEffect(() => {
    if (solved) void reportSolved();
  }, [solved, reportSolved]);

  useEffect(() => {
    if (alarmStopped && celebrated) returnHome.current?.(occurrenceId);
  }, [alarmStopped, celebrated, occurrenceId]);

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
      if (draft.length !== wordLength) {
        setMessage(`Enter ${wordLength} letters.`);
      } else if (!isWord(draft)) {
        setMessage('That word is not in the puzzle dictionary.');
      } else {
        void persist([...puzzle.guesses, draft]);
      }
      return;
    }
    setMessage('');
    setDraft((value) => key === 'Delete' ? value.slice(0, -1) : (value + key.toLowerCase()).slice(0, wordLength));
  }

  const marks = puzzle ? keyboardMarks(puzzle.guesses, puzzle.answer) : {};
  const guessCount = puzzle?.guesses.length ?? 0;
  const mood = solved ? 'happy' : guessCount ? 'angry' : 'calm';
  const status = message || (exhausted ? 'Six guesses used. Try the same word on a fresh board.' : '');

  return (
    <SafeAreaView style={styles.safe}>
      <ScrollView contentContainerStyle={styles.content}>
        <PuzzleHeader alarmTime={alarmTime} mood={mood} guessCount={guessCount} onCelebrated={setCelebrated} />
        {puzzle && <Text style={styles.instructions}>Find the {wordLength}-letter word in six guesses.</Text>}
        {loading && <ActivityIndicator color="#333F48" style={styles.loading} />}
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
                    {Array.from({ length: wordLength }, (_, col) => {
                      const mark = rowMarks[col];
                      const letter = letters[col]?.toUpperCase();
                      return (
                        <View
                          key={col}
                          accessible
                          accessibilityLabel={letter ? `${letter}, ${MARK_LABEL[mark] ?? 'unsubmitted'}` : 'Empty tile'}
                          style={[styles.tile, { width: tile, height: tile }, letter && styles.filled, styles[mark]]}
                        >
                          <Text style={[styles.letter, (!mark || mark === 'absent') && styles.lightLetter]}>{letter}</Text>
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
                        <Text style={[styles.keyText, (!mark || mark === 'absent') && styles.lightLetter, wide && styles.wideText]}>{key === 'Delete' ? '⌫' : key}</Text>
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
      <Text style={[styles.keyText, styles.lightLetter]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#A2B8C6' },
  content: { width: '100%', maxWidth: 460, alignSelf: 'center', paddingHorizontal: 14, paddingVertical: 14 },
  instructions: { textAlign: 'center', color: '#101A20', marginTop: 5, marginBottom: 16 },
  loading: { margin: 24 },
  board: { gap: 5, alignItems: 'center' },
  tiles: { flexDirection: 'row', gap: 5 },
  tile: { borderWidth: 1, borderColor: '#BDD0DA', borderRadius: 8, backgroundColor: '#333F48', alignItems: 'center', justifyContent: 'center' },
  filled: { borderColor: '#FFDAB9', borderWidth: 2 },
  letter: { color: '#101A20', fontSize: 24, fontWeight: '800' },
  lightLetter: { color: '#FFFFFF' },
  exact: { backgroundColor: '#008B8B', borderColor: '#008B8B' },
  present: { backgroundColor: '#FFDAB9', borderColor: '#FFDAB9' },
  absent: { backgroundColor: '#DC143C', borderColor: '#DC143C' },
  feedback: { minHeight: 40, justifyContent: 'center', alignItems: 'center', paddingVertical: 4 },
  status: { color: '#101A20', textAlign: 'center', fontWeight: '600' },
  action: { backgroundColor: '#333F48', borderRadius: 10, padding: 12, marginTop: 6 },
  keyboard: { gap: 5 },
  keyRow: { flexDirection: 'row', gap: 3, justifyContent: 'center' },
  key: { flex: 1, maxWidth: 42, minHeight: 46, backgroundColor: '#333F48', borderRadius: 7, justifyContent: 'center', alignItems: 'center' },
  wideKey: { flex: 1.45, maxWidth: 55 },
  keyText: { color: '#101A20', fontSize: 15, fontWeight: '800' },
  wideText: { fontSize: 12 },
  pressed: { opacity: 0.72 },
});
