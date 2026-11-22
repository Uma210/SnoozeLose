import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import WordPuzzleScreen from './src/word-game/WordPuzzleScreen';
import { prepareWordPuzzle, selectDatabaseWord } from './src/word-game/puzzles';

export default function App() {
  const [occurrenceId, setOccurrenceId] = useState(() => `preview:word:${Date.now()}`);
  const [ready, setReady] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (occurrenceId === null) return;
    let active = true;
    prepareWordPuzzle(occurrenceId, selectDatabaseWord).then(
      () => { if (active) setReady(true); },
      (failure) => { if (active) setError(failure.message); },
    );
    return () => { active = false; };
  }, [occurrenceId]);

  return (
    <SafeAreaProvider>
      {occurrenceId === null ? (
        <SafeAreaView style={styles.loading}>
          <Text accessibilityRole="header" style={styles.homeTitle}>Snooze Loose</Text>
          <Pressable
            accessibilityRole="button"
            onPress={() => {
              setReady(false);
              setError('');
              setOccurrenceId(`preview:word:${Date.now()}`);
            }}
            style={styles.playButton}
          >
            <Text style={styles.playLabel}>Play again</Text>
          </Pressable>
        </SafeAreaView>
      ) : ready ? (
        <WordPuzzleScreen occurrenceId={occurrenceId} onWinAnimationComplete={() => setOccurrenceId(null)} />
      ) : (
        <SafeAreaView style={styles.loading}>
          {error ? <Text accessibilityRole="alert" style={styles.error}>{error}</Text> : (
            <ActivityIndicator accessibilityLabel="Preparing puzzle" color="#333F48" />
          )}
        </SafeAreaView>
      )}
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  error: { color: '#18232C' },
  homeTitle: { color: '#18232C', fontSize: 26, fontWeight: '800', marginBottom: 20 },
  playButton: { backgroundColor: '#333F48', borderRadius: 10, padding: 14 },
  playLabel: { color: '#FFFFFF', fontWeight: '700' },
  loading: {
    flex: 1,
    backgroundColor: '#A2B8C6',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 22,
  },
});
