import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/ball.dart';
import 'components/bat.dart';
import 'components/brick.dart';
import 'components/play_area.dart';
import 'config.dart';

enum PlayState { welcome, playing, gameOver, won }

class BrickBreaker extends FlameGame
    with HasCollisionDetection, KeyboardEvents, TapDetector {
  BrickBreaker()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: gameWidth,
            height: gameHeight,
          ),
        );

  final rand = math.Random();
  double get width => size.x;
  double get height => size.y;
  final ValueNotifier<int> score = ValueNotifier(0);

  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState newState) {
    _playState = newState;
    switch (newState) {
      case PlayState.welcome:
         overlays.add('welcome');
        break;
      case PlayState.playing:
        overlays.remove('welcome');
        overlays.remove('gameOver');
        overlays.remove('won');
        break;
      case PlayState.gameOver:
        overlays.add('gameOver');
        break;
      case PlayState.won:
        overlays.add('won');
        break;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(PlayArea());
    playState = PlayState.welcome;
  }

  void startGame() {
    if (_playState == PlayState.playing) return;

    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());

    playState = PlayState.playing;
    score.value = 0;

    world.add(Ball(
        difficultyModifier: difficultyModifier,
        radius: ballRadius,
        position: size / 2,
        velocity: Vector2((rand.nextDouble() - 0.5) * width, height * 0.2)
            .normalized()
          ..scale(height / 4)));

    world.add(Bat(
        size: Vector2(batWidth, batHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95)));

    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 5; j++)
          Brick(
            position: Vector2(
              (i + 0.5) * brickWidth + (i + 1) * brickGutter,
              (j + 2.0) * brickHeight + j * brickGutter,
            ),
            color: brickColors[i],
          ),
    ]);
  }

  @override
  void onTap() {
    super.onTap();
    if (_playState == PlayState.welcome || _playState == PlayState.gameOver || _playState == PlayState.won) {
      startGame();
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    super.onKeyEvent(event, keysPressed);
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          world.children.query<Bat>().first.moveBy(-batStep);
          break;
        case LogicalKeyboardKey.arrowRight:
          world.children.query<Bat>().first.moveBy(batStep);
          break;
        case LogicalKeyboardKey.space:
        case LogicalKeyboardKey.enter:
          if (_playState == PlayState.welcome || _playState == PlayState.gameOver || _playState == PlayState.won) {
            startGame();
          }
          break;
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Color backgroundColor() => const Color(0xfff2e8cf);  // Custom background color
}
