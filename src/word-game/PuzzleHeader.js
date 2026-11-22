import React, { useEffect, useRef, useState } from 'react';
import { useFonts } from 'expo-font';
import { AccessibilityInfo, Animated, Easing, Platform, StyleSheet, Text, View } from 'react-native';

const FONT = require('../../assets/fonts/PressStart2P-Regular.ttf');
export default function PuzzleHeader({ alarmTime, mood, guessCount, onCelebrated }) {
  const [fontLoaded] = useFonts({ 'Press Start 2P': FONT });
  const [reduceMotion, setReduceMotion] = useState(null);
  const reaction = useRef(new Animated.Value(0)).current;
  const motion = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (Platform.OS === 'web' && typeof window !== 'undefined' && window.matchMedia) {
      const query = window.matchMedia('(prefers-reduced-motion: reduce)');
      const update = () => setReduceMotion(query.matches);
      update();
      query.addEventListener?.('change', update);
      return () => query.removeEventListener?.('change', update);
    }
    let active = true;
    const preference = AccessibilityInfo.isReduceMotionEnabled?.();
    Promise.resolve(preference ?? true).then(
      (enabled) => { if (active) setReduceMotion(enabled); },
      () => { if (active) setReduceMotion(true); },
    );
    const listener = AccessibilityInfo.addEventListener?.('reduceMotionChanged', setReduceMotion);
    return () => {
      active = false;
      listener?.remove();
    };
  }, []);

  useEffect(() => {
    if (reduceMotion !== false) {
      motion.setValue(0);
      return;
    }
    const config = { easing: Easing.inOut(Easing.sin), useNativeDriver: Platform.OS !== 'web', isInteraction: false };
    const loop = Animated.loop(Animated.sequence([
      Animated.timing(motion, { ...config, toValue: 1, duration: 2300 }),
      Animated.timing(motion, { ...config, toValue: 0, duration: 2300 }),
    ]));
    loop.start();
    return () => loop.stop();
  }, [motion, reduceMotion]);

  const titleFloat = motion.interpolate({ inputRange: [0, 1], outputRange: [0, -4] });
  useEffect(() => {
    reaction.setValue(0);
    if (!guessCount || reduceMotion === null) return;
    if (reduceMotion) {
      if (mood === 'happy') onCelebrated(true);
      return;
    }
    const animation = Animated.timing(reaction, {
      toValue: 1,
      duration: mood === 'happy' ? 740 : 460,
      easing: Easing.linear,
      useNativeDriver: Platform.OS !== 'web',
      isInteraction: false,
    });
    animation.start(({ finished }) => {
      if (finished && mood === 'happy') onCelebrated(true);
    });
    return () => animation.stop();
  }, [guessCount, mood, onCelebrated, reaction, reduceMotion]);

  const jump = reaction.interpolate({
    inputRange: [0, 0.28, 0.62, 0.82, 1],
    outputRange: mood === 'happy' ? [0, -24, 0, -9, 0] : [0, -17, -13, -4, 0],
  });
  const spin = reaction.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '360deg'] });
  const font = (fontLoaded || Platform.OS === 'web') && styles.pixelFont;

  return (
    <View style={styles.header}>
      <Animated.View style={[styles.titles, { transform: [{ translateY: titleFloat }] }]}>
        <Text style={[styles.brand, font]}>Snooze Loose</Text>
        <Text accessibilityRole="header" style={[styles.title, font]}>Solve to Stop</Text>
      </Animated.View>
      {alarmTime ? <Text style={styles.time}>{alarmTime}</Text> : null}
      <View pointerEvents="none" style={styles.mascotArea}>
        <Animated.View accessible accessibilityRole="image" accessibilityLabel={`Nightcap penguin, ${mood}`} style={[
          styles.sprite,
          { transform: [{ translateY: jump }, { rotate: mood === 'happy' ? '0deg' : spin }] },
        ]}>
          <View style={[styles.flipper, styles.leftFlipper]} />
          <View style={[styles.flipper, styles.rightFlipper]} />
          <View style={[styles.foot, { left: 17 }]} />
          <View style={[styles.foot, { right: 17 }]} />
          <View style={styles.body} />
          <View style={styles.belly} />
          <View style={styles.cap} />
          <View style={styles.capBand} />
          <View style={styles.pom} />
          <PenguinEye side="left" mood={mood} />
          <PenguinEye side="right" mood={mood} />
          <View style={styles.beak} />
        </Animated.View>
      </View>
    </View>
  );
}

function PenguinEye({ side, mood }) {
  const left = side === 'left';
  const tilt = mood === 'angry' ? (left ? '25deg' : '-25deg') : '0deg';
  return (
    <View style={[styles.eyeGroup, left ? { left: 20 } : { right: 20 }]}>
      <View style={[styles.brow, { transform: [{ rotate: tilt }] }]} />
      {mood === 'happy' ? (
        <View style={styles.happyEye}>
          <View style={styles.happyArc} />
        </View>
      ) : <View style={[styles.pupil, mood === 'angry' && styles.angryEye]} />}
    </View>
  );
}

const styles = StyleSheet.create({
  header: { alignItems: 'center', paddingTop: 8, gap: 5 },
  titles: { alignItems: 'center', gap: 10 },
  pixelFont: {
    fontFamily: Platform.select({ web: '"Press Start 2P", monospace', default: 'Press Start 2P' }),
    fontWeight: 'normal',
  },
  brand: { color: '#333F48', fontSize: 13, lineHeight: 19, fontWeight: '700', textAlign: 'center' },
  title: { color: '#18232C', fontSize: 19, lineHeight: 27, fontWeight: '800', textAlign: 'center' },
  time: { color: '#333F48', fontSize: 14, fontWeight: '600' },
  mascotArea: { width: '100%', minHeight: 72, alignItems: 'center', justifyContent: 'center' },
  sprite: { width: 74, height: 68 },
  body: { position: 'absolute', top: 17, left: 12, width: 50, height: 47, borderRadius: 24, backgroundColor: '#1D2B37' },
  belly: { position: 'absolute', top: 24, left: 17, width: 40, height: 37, borderRadius: 21, backgroundColor: '#F5F9FC' },
  flipper: { position: 'absolute', top: 39, width: 15, height: 19, borderRadius: 9, backgroundColor: '#1D2B37' },
  leftFlipper: { left: 7, transform: [{ rotate: '30deg' }] },
  rightFlipper: { right: 7, transform: [{ rotate: '-30deg' }] },
  foot: { position: 'absolute', bottom: 1, width: 16, height: 8, borderRadius: 7, backgroundColor: '#F6AD72' },
  cap: { position: 'absolute', top: 4, left: 21, width: 36, height: 20, borderTopLeftRadius: 24, borderTopRightRadius: 15, backgroundColor: '#8CA8C2', transform: [{ rotate: '-15deg' }] },
  capBand: { position: 'absolute', left: 19, top: 17, width: 40, height: 6, borderRadius: 5, backgroundColor: '#D5E4EE', transform: [{ rotate: '-10deg' }] },
  pom: { position: 'absolute', top: 3, right: 13, width: 10, height: 10, borderRadius: 5, backgroundColor: '#FFDAB9' },
  eyeGroup: { position: 'absolute', top: 29, width: 14, alignItems: 'center' },
  brow: { width: 12, height: 2.5, borderRadius: 2, backgroundColor: '#18232C', marginBottom: 2 },
  pupil: { width: 5, height: 7, borderRadius: 3, backgroundColor: '#18232C' },
  angryEye: { height: 5, width: 6 },
  happyEye: { width: 12, height: 6, overflow: 'hidden' },
  happyArc: { width: 12, height: 13, borderWidth: 2, borderColor: '#18232C', borderRadius: 6 },
  beak: { position: 'absolute', top: 46, left: 31, width: 0, height: 0, borderLeftWidth: 6, borderRightWidth: 6, borderTopWidth: 7, borderLeftColor: 'transparent', borderRightColor: 'transparent', borderTopColor: '#F6AA36', borderStyle: 'solid' },
});
