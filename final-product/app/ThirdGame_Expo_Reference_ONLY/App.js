import React, { useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, Vibration, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import WordPuzzleScreen from './src/word-game/WordPuzzleScreen';
import { loadWordPuzzle, prepareWordPuzzle, selectDatabaseWord, SAMPLE_PUZZLE_ID, saveWordPuzzle } from './src/word-game/puzzles';
import KrillionPuzzleScreen from './src/krillion/KrillionPuzzleScreen';
import { prepareKrillionPuzzle } from './src/krillion/puzzles';

export default function App() {
  const [current, setCurrent] = useState(null);
  const [krillion, setKrillion] = useState(null);
  const [solved, setSolved] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!krillion) return;
    Vibration.vibrate([0, 500, 650], true);
    return () => Vibration.cancel();
  }, [krillion]);

  async function start(useAi) {
    setPending(true);
    setError('');
    try {
      const id = useAi ? `preview:word:${Date.now()}` : SAMPLE_PUZZLE_ID;
      if (useAi) {
        await prepareWordPuzzle(id, selectDatabaseWord);
      } else {
        const sample = await loadWordPuzzle(id);
        if (!sample || sample.guesses.includes(sample.answer)) {
          await saveWordPuzzle({ occurrenceId: id, answer: 'crane', guesses: [] });
        }
      }
      setSolved(false);
      setCurrent(id);
    } catch (failure) {
      setError(failure.message);
    } finally {
      setPending(false);
    }
  }

  async function startKrillion() {
    setPending(true);
    setError('');
    try {
      const now = new Date();
      const occurrenceId = `preview:krillion:${now.getTime()}`;
      await prepareKrillionPuzzle(occurrenceId);
      setSolved(false);
      setCurrent(null);
      setKrillion({ occurrenceId, alarmTime: now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) });
    } catch (failure) {
      setError(failure.message);
    } finally {
      setPending(false);
    }
  }

  function finishKrillion(occurrenceId) {
    if (krillion?.occurrenceId !== occurrenceId) return;
    Vibration.cancel();
    setKrillion(null);
    setSolved(true);
  }

  return (
    <SafeAreaProvider>
      {krillion ? (
        <KrillionPuzzleScreen {...krillion} onSolved={finishKrillion} />
      ) : current && !solved ? (
        <WordPuzzleScreen occurrenceId={current} onSolved={() => setSolved(true)} />
      ) : (
        <SafeAreaView style={styles.safe}>
          <View style={styles.panel}>
            <Text style={styles.brand}>SnoozeLose</Text>
            <Text accessibilityRole="header" style={styles.heading}>{solved ? 'Puzzle solved' : 'Alarm puzzles'}</Text>
            <Text style={styles.copy}>{solved ? 'Choose another preview to keep playing.' : 'Try the game your alarm will open.'}</Text>
            {solved && <PreviewButton label="Back to preview" onPress={() => { setCurrent(null); setSolved(false); }} />}
            {!solved && (
              <>
                <PreviewButton label="Play sample puzzle" disabled={pending} onPress={() => start(false)} />
                <PreviewButton label={pending ? 'Preparing…' : 'Play a new puzzle'} disabled={pending} onPress={() => start(true)} />
                <PreviewButton label="Preview Krillion alarm" disabled={pending} onPress={startKrillion} />
              </>
            )}
            {!!error && <Text accessibilityRole="alert" style={styles.copy}>{error}</Text>}
          </View>
        </SafeAreaView>
      )}
    </SafeAreaProvider>
  );
}

function PreviewButton({ label, onPress, disabled }) {
  return (
    <Pressable accessibilityRole="button" disabled={disabled} onPress={onPress} style={styles.button}>
      <Text style={styles.buttonText}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#E0FFFF', justifyContent: 'center', alignItems: 'center', padding: 22 },
  panel: { width: '100%', maxWidth: 360, padding: 24, gap: 12, borderRadius: 18, backgroundColor: '#F6FFFF', borderWidth: 1, borderColor: '#B0BACF' },
  brand: { color: '#46348F', fontWeight: '800', fontSize: 16 },
  heading: { color: '#1D2141', fontWeight: '800', fontSize: 34 },
  copy: { color: '#384565', fontSize: 16, marginBottom: 5 },
  button: { alignItems: 'center', backgroundColor: '#6A5ACD', padding: 14, borderRadius: 10 },
  buttonText: { color: '#FFFFFF', fontWeight: '800', fontSize: 16 },
});
