import React, { useEffect, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, Easing, Image, StyleSheet, Text, View } from 'react-native';
import { echoDepth } from './rules';

const SURFACE = 0.265;
const BOTTOM = 0.83;
const OCEAN_RATIO = 840 / 1260;
const ocean = require('./assets/ocean.jpg');
const penguin = require('./assets/penguin.png');
const ticks = [0, 500, 1000];

export default function OceanScene({ points, children }) {
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [reducedMotion, setReducedMotion] = useState(true);
  const descent = useRef(new Animated.Value(0)).current;
  const stroke = useRef(new Animated.Value(0)).current;
  const current = useRef(new Animated.Value(0)).current;
  const depth = echoDepth(points);

  useEffect(() => {
    let active = true;
    AccessibilityInfo.isReduceMotionEnabled().then(value => { if (active) setReducedMotion(value); }).catch(() => {});
    const listener = AccessibilityInfo.addEventListener('reduceMotionChanged', setReducedMotion);
    return () => { active = false; listener.remove(); };
  }, []);

  useEffect(() => {
    current.setValue(0);
    if (reducedMotion) return;
    const wave = Animated.loop(Animated.timing(current, {
      toValue: 1, duration: 4200, easing: Easing.linear, useNativeDriver: true, isInteraction: false,
    }));
    wave.start();
    return () => wave.stop();
  }, [current, reducedMotion]);

  useEffect(() => {
    stroke.setValue(0);
    if (!depth || reducedMotion) {
      descent.setValue(depth / 1000);
      return;
    }
    const swim = Animated.parallel([
      Animated.timing(descent, { toValue: depth / 1000, duration: 930, easing: Easing.out(Easing.cubic), useNativeDriver: true }),
      Animated.timing(stroke, { toValue: 1, duration: 930, easing: Easing.linear, useNativeDriver: true }),
    ]);
    swim.start();
    return () => swim.stop();
  }, [depth, descent, reducedMotion, stroke]);

  const imageWidth = Math.max(size.width, size.height * OCEAN_RATIO);
  const imageHeight = imageWidth / OCEAN_RATIO;
  const trackHeight = size.height * (BOTTOM - SURFACE);
  const swimmerSize = Math.min(122, Math.max(78, size.width * 0.24));
  const drift = stroke.interpolate({ inputRange: [0, 1], outputRange: [0, size.width * 0.18] });
  const rotation = stroke.interpolate({ inputRange: [0, 0.28, 0.52, 0.72, 1], outputRange: ['-6deg', '42deg', '24deg', '35deg', '7deg'] });
  const fall = descent.interpolate({ inputRange: [0, 1], outputRange: [0, Math.max(1, trackHeight)] });
  const shimmer = current.interpolate({ inputRange: [0, 1], outputRange: [0, -48] });
  const bubbleRise = stroke.interpolate({ inputRange: [0, 1], outputRange: [4, -34] });
  const bubbleOpacity = stroke.interpolate({ inputRange: [0, 0.22, 1], outputRange: [0, 0.9, 0] });

  return (
    <View style={styles.ocean} onLayout={({ nativeEvent }) => setSize(nativeEvent.layout)}>
      {size.height > 0 && (
        <View pointerEvents="none" accessible={false} importantForAccessibility="no-hide-descendants" style={StyleSheet.absoluteFill}>
          <Image source={ocean} style={[styles.art, {
            width: imageWidth, height: imageHeight, left: (size.width - imageWidth) / 2,
            top: (size.height - imageHeight) * SURFACE,
          }]} />
          {!reducedMotion && (
            <Animated.View style={[styles.current, { top: size.height * SURFACE - 2, transform: [{ translateX: shimmer }] }]}>
              {Array.from({ length: Math.ceil(size.width / 48) + 3 }, (_, index) => <View key={index} style={styles.glint} />)}
            </Animated.View>
          )}
          {ticks.map((mark, index) => (
            <View key={mark} style={[styles.tick, { top: size.height * SURFACE + trackHeight * index / 2 - 8 }]}>
              <Text style={styles.tickText}>{mark.toLocaleString('en-US')} m</Text>
              <View style={styles.tickLine} />
            </View>
          ))}
          <Animated.View style={[styles.swimmer, {
            top: size.height * SURFACE - swimmerSize / 2,
            left: size.width * 0.43 - swimmerSize / 2 + (reducedMotion && depth ? size.width * 0.18 : 0),
            width: swimmerSize, height: swimmerSize,
            transform: [{ translateX: drift }, { translateY: fall }],
          }]}>
            {!reducedMotion && (
              <Animated.View style={[styles.bubbles, { opacity: bubbleOpacity, transform: [{ translateY: bubbleRise }] }]}>
                <View style={[styles.bubble, styles.bubbleLarge]} />
                <View style={[styles.bubble, styles.bubbleSmall]} />
              </Animated.View>
            )}
            <Animated.Image source={penguin} resizeMode="contain" style={[styles.penguin, { transform: [{ rotate: rotation }] }]} />
          </Animated.View>
        </View>
      )}
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  ocean: { flex: 1, minHeight: 210, overflow: 'hidden', backgroundColor: '#081831' },
  art: { position: 'absolute' },
  current: { position: 'absolute', left: -4, height: 5, flexDirection: 'row', gap: 26 },
  glint: { width: 22, height: 2, marginTop: 1, borderRadius: 2, backgroundColor: '#B9F3FFB0' },
  tick: { position: 'absolute', left: 15, right: 15, flexDirection: 'row', alignItems: 'center', gap: 8 },
  tickText: { color: '#E3EFFF', fontSize: 12, fontWeight: '700', backgroundColor: '#081831CF', borderRadius: 4, paddingHorizontal: 5 },
  tickLine: { flex: 1, borderTopWidth: 1, borderStyle: 'dashed', borderColor: '#B7DEFF55' },
  swimmer: { position: 'absolute' },
  penguin: { width: '100%', height: '100%' },
  bubbles: { position: 'absolute', top: '58%', left: 1 },
  bubble: { borderWidth: 1, borderColor: '#B7F3FF', borderRadius: 8, backgroundColor: '#9FEAFF35' },
  bubbleLarge: { width: 9, height: 9, marginLeft: 8, marginBottom: 5 },
  bubbleSmall: { width: 6, height: 6 },
});
