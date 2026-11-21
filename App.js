import React, { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import WordPuzzleScreen from './src/word-game/WordPuzzleScreen';
import { loadWordPuzzle, prepareWordPuzzle, selectDatabaseWord, SAMPLE_PUZZLE_ID, saveWordPuzzle } from './src/word-game/puzzles';

export default function App() {
  const [current, setCurrent] = useState(null);
  const [solved, setSolved] = useState(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState('');

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

  return (
    <SafeAreaProvider>
      {current && !solved ? (
        <WordPuzzleScreen occurrenceId={current} onSolved={() => setSolved(true)} />
      ) : (
        <SafeAreaView style={styles.safe}>
          <View style={styles.panel}>
            <Text style={styles.brand}>SnoozeLose</Text>
            <Text accessibilityRole="header" style={styles.heading}>{solved ? 'Puzzle solved' : 'Word puzzle'}</Text>
            <Text style={styles.copy}>{solved ? 'Choose another preview to keep playing.' : 'Try the game your alarm will open.'}</Text>
            {solved && <PreviewButton label="Back to preview" onPress={() => { setCurrent(null); setSolved(false); }} />}
            {!solved && (
              <>
                <PreviewButton label="Play sample puzzle" disabled={pending} onPress={() => start(false)} />
                <PreviewButton label={pending ? 'Preparing…' : 'Play a new puzzle'} disabled={pending} onPress={() => start(true)} />
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
