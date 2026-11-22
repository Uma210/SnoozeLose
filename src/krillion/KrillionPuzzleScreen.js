import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator, BackHandler, Keyboard, KeyboardAvoidingView, Platform,
  Pressable, ScrollView, StatusBar, StyleSheet, Text, TextInput, View,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import OceanScene from './OceanScene';
import { restartKrillionPuzzle, updateKrillionPuzzle } from './puzzles';
import { advanceDive, answerPrompt, beginPrompt, DIVE_LENGTH, echoDepth, echoTier, missCount, PROMPT_TIME } from './rules';

export default function KrillionPuzzleScreen(props) {
  return <DiveSession key={props.occurrenceId} {...props} />;
}

function DiveSession({ occurrenceId, alarmTime, onSolved }) {
  const [puzzle, setPuzzle] = useState(null);
  const [now, setNow] = useState(Date.now);
  const [draft, setDraft] = useState('');
  const [saving, setSaving] = useState(false);
  const [issue, setIssue] = useState('');
  const [completionError, setCompletionError] = useState(false);
  const mounted = useRef(true);
  const busy = useRef(false);
  const completing = useRef(false);
  const completion = useRef(onSolved);
  completion.current = onSolved;

  const persist = useCallback(async (work) => {
    if (busy.current) return;
    busy.current = true;
    setSaving(true);
    setIssue('');
    try {
      const saved = await work();
      if (mounted.current) {
        setPuzzle(saved);
        setDraft('');
        setNow(Date.now());
      }
    } catch (error) {
      if (mounted.current) setIssue(error.message || 'Could not save this dive.');
    } finally {
      busy.current = false;
      if (mounted.current) setSaving(false);
    }
  }, []);

  const load = useCallback(() => persist(() => updateKrillionPuzzle(
    occurrenceId, saved => beginPrompt(saved, Date.now()),
  )), [occurrenceId, persist]);

  useEffect(() => {
    mounted.current = true;
    load();
    const back = BackHandler.addEventListener('hardwareBackPress', () => true);
    return () => { mounted.current = false; back.remove(); };
  }, [load]);

  const submit = useCallback((value, timestamp) => {
    if (!puzzle || puzzle.phase !== 'playing' || issue || busy.current) return;
    Keyboard.dismiss();
    void persist(() => updateKrillionPuzzle(occurrenceId, saved => answerPrompt(
      saved, puzzle.results.length, value, timestamp,
    )));
  }, [issue, occurrenceId, persist, puzzle]);

  useEffect(() => {
    if (!puzzle || issue) return;
    if (puzzle.phase === 'feedback') {
      const timer = setTimeout(() => {
        void persist(() => updateKrillionPuzzle(occurrenceId, saved => advanceDive(saved, Date.now())));
      }, Math.max(0, puzzle.advanceAt - Date.now()));
      return () => clearTimeout(timer);
    }
    if (puzzle.phase !== 'playing') return;
    const tick = () => {
      const timestamp = Date.now();
      setNow(timestamp);
      if (timestamp - puzzle.startedAt >= PROMPT_TIME) submit('', timestamp);
    };
    const timer = setInterval(tick, 100);
    return () => clearInterval(timer);
  }, [issue, occurrenceId, persist, puzzle, submit]);

  const reportSolved = useCallback(async () => {
    if (completing.current) return;
    completing.current = true;
    setCompletionError(false);
    try {
      await completion.current(occurrenceId);
    } catch {
      completing.current = false;
      if (mounted.current) setCompletionError(true);
    }
  }, [occurrenceId]);
  useEffect(() => {
    if (puzzle?.phase === 'solved') void reportSolved();
  }, [puzzle?.phase, reportSolved]);

  function restart(simpler) {
    void persist(async () => {
      await restartKrillionPuzzle(occurrenceId, simpler);
      return updateKrillionPuzzle(occurrenceId, saved => beginPrompt(saved, Date.now()));
    });
  }

  const phase = puzzle?.phase;
  const playing = phase === 'playing';
  const misses = puzzle ? missCount(puzzle) : 0;
  const score = puzzle?.results.reduce((total, result) => total + result.points, 0) ?? 0;
  const index = puzzle ? puzzle.results.length - (playing ? 0 : 1) : 0;
  const prompt = puzzle?.prompts[index];
  const feedback = phase === 'feedback' ? puzzle.results.at(-1) : null;
  const points = feedback?.points ?? 0;
  const depth = echoDepth(points);
  const left = playing ? Math.min(PROMPT_TIME, Math.max(0, PROMPT_TIME - (now - puzzle.startedAt))) : 0;
  const editable = playing && !saving && !issue;

  return (
    <SafeAreaView style={styles.safe}>
      <StatusBar barStyle="light-content" />
      <KeyboardAvoidingView style={styles.safe} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          <OceanScene points={points}>
            <View style={styles.hud}>
              <View style={styles.hudColumn}>
                <Text accessibilityRole="header" style={styles.title}>Krillion</Text>
                <Text style={styles.hudLabel}>{alarmTime || 'SnoozeLose'}</Text>
              </View>
              <View style={styles.depth}>
                <Text style={styles.hudLabel}>Echo depth</Text>
                <Text style={styles.depthValue}>{depth ? `${depth.toLocaleString('en-US')} m` : 'Surface'}</Text>
              </View>
            </View>
          </OceanScene>
          <View style={styles.card}>
            {issue ? (
              <>
                <Text accessibilityRole="alert" style={styles.status}>{issue}</Text>
                <Action label="Reload dive" disabled={saving} onPress={load} />
              </>
            ) : !puzzle ? (
              <ActivityIndicator accessibilityLabel="Loading Krillion" color="#59B8CF" />
            ) : phase === 'solved' ? (
              <>
                <Text accessibilityRole="header" style={styles.question}>Dive complete</Text>
                <Text style={styles.status}>{completionError ? 'Could not dismiss the alarm.' : 'Dismissing the alarm…'}</Text>
                {completionError && <Action label="Finish alarm" onPress={reportSolved} />}
              </>
            ) : phase === 'restart' ? (
              <>
                <Text accessibilityRole="header" style={styles.question}>Restart the dive</Text>
                <Text style={styles.status}>Three misses. Complete a new dive to stop the alarm.</Text>
                <Action label={puzzle.mode === 'simpler' ? 'Restart dive' : 'Restart at same difficulty'} disabled={saving} onPress={() => restart(false)} />
                {puzzle.mode === 'standard' && <Action label="Restart with simpler prompts" disabled={saving} onPress={() => restart(true)} secondary />}
              </>
            ) : (
              <>
                <View style={styles.meta}>
                  <Text style={styles.metaLabel}>{index + 1}/{DIVE_LENGTH} · {puzzle.mode === 'simpler' ? 'Simpler' : 'Standard'}</Text>
                  <Text style={styles.metaLabel}>Score {score}</Text>
                  <Text style={styles.metaLabel}>{Math.ceil(left / 1000)}s</Text>
                </View>
                <View style={styles.timer} accessible={false}>
                  <View style={[styles.timerFill, { width: `${left / PROMPT_TIME * 100}%` }, left < 6000 && styles.timerLow]} />
                </View>
                <Text accessibilityRole="header" style={styles.question}>{prompt}</Text>
                <View style={styles.row}>
                  <TextInput
                    accessibilityLabel="Your answer"
                    style={styles.input}
                    placeholder="Your answer…"
                    placeholderTextColor="#9BACCC"
                    autoCapitalize="none"
                    autoCorrect={false}
                    editable={Boolean(editable)}
                    returnKeyType="go"
                    value={draft}
                    onChangeText={setDraft}
                    onSubmitEditing={() => submit(draft, Date.now())}
                  />
                  <Action label="Echo" disabled={!editable} onPress={() => submit(draft, Date.now())} />
                </View>
                {feedback && (
                  <Text accessibilityLiveRegion="polite" style={styles.status}>
                    {points ? `Echo! +${points} points · ${echoTier(points)} · ${depth} m` : `${feedback.answer ? 'No echo.' : 'Time’s up.'} Try something like “${feedback.hint}”.`}
                  </Text>
                )}
                <Text style={styles.metaLabel}>Misses {misses}/3</Text>
              </>
            )}
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

function Action({ label, onPress, disabled, secondary }) {
  return (
    <Pressable accessibilityRole="button" disabled={disabled} onPress={onPress}
      style={({ pressed }) => [styles.action, secondary && styles.secondary, (disabled || pressed) && styles.dim]}>
      <Text style={[styles.actionText, secondary && styles.secondaryText]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1, backgroundColor: '#081831' },
  content: { flexGrow: 1 },
  hud: { flexDirection: 'row', justifyContent: 'space-between', gap: 16, padding: 16, backgroundColor: '#091932E8' },
  hudColumn: { flexShrink: 1 },
  title: { color: '#F4FAFF', fontSize: 23, fontWeight: '800' },
  hudLabel: { color: '#BECEE8', fontSize: 13, fontWeight: '600' },
  depth: { alignItems: 'flex-end', paddingTop: 2 },
  depthValue: { color: '#A6F4E6', fontSize: 20, fontWeight: '800', fontVariant: ['tabular-nums'] },
  card: { marginHorizontal: 12, marginTop: -12, marginBottom: 10, padding: 16, borderRadius: 22, gap: 10, borderWidth: 1, borderColor: '#536B91', backgroundColor: '#142640' },
  meta: { flexDirection: 'row', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8 },
  metaLabel: { color: '#BAD0E9', fontSize: 14, fontWeight: '700', fontVariant: ['tabular-nums'] },
  timer: { height: 7, borderRadius: 4, backgroundColor: '#324764', overflow: 'hidden' },
  timerFill: { height: '100%', backgroundColor: '#7BDCD9' },
  timerLow: { backgroundColor: '#FFA68F' },
  question: { color: '#F5FAFF', fontSize: 22, lineHeight: 28, fontWeight: '800' },
  status: { color: '#D4E3F7', fontSize: 15, lineHeight: 21 },
  row: { flexDirection: 'row', alignItems: 'stretch', gap: 8 },
  input: { flex: 1, minWidth: 0, minHeight: 50, color: '#F5FAFF', paddingHorizontal: 12, borderWidth: 1, borderColor: '#506C90', borderRadius: 13, backgroundColor: '#0C1B31', fontSize: 16 },
  action: { minHeight: 50, justifyContent: 'center', alignItems: 'center', paddingVertical: 10, paddingHorizontal: 14, borderRadius: 13, backgroundColor: '#FFC793' },
  actionText: { color: '#192D45', textAlign: 'center', fontSize: 16, fontWeight: '800' },
  secondary: { borderWidth: 1, borderColor: '#7293BA', backgroundColor: '#283F60' },
  secondaryText: { color: '#F2F7FF' },
  dim: { opacity: 0.58 },
});
