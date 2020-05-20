import 'dart:io';

import 'package:flame/flame.dart';
import 'package:flame/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Game.dart';

void _setTargetPlatformForDesktop() {
  // No need to handle macOS, as it has now been added to TargetPlatform.
  if (Platform.isLinux || Platform.isWindows) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() {
  _setTargetPlatformForDesktop();
  WidgetsFlutterBinding.ensureInitialized();

  Util flameUtil = Util();
  flameUtil.fullScreen();
  flameUtil.setOrientation(DeviceOrientation.portraitUp);
  Flame.images.loadAll(<String>[
    'poker1.png',
    'avatar/1.png',
    'avatar/2.png',
    'avatar/3.png',
    'avatar/4.png',
    'avatar/5.png',
    'avatar/6.png'
    // 'ground.png',
    // 'wall/wall_down_close_left.png',
    // 'wall/wall_down_close_right.png',
    // 'wall/wall_down.png',
    // 'wall/wall_side_bottom_left.png',
    // 'wall/wall_side_bottom_right.png',
    // 'wall/wall_side_top_left.png',
    // 'wall/wall_side_top_right.png',
    // 'wall/wall_up_close_bottom.png',
    // 'wall/wall_up_close_top.png',
    // 'wall/wall_up.png',
    // 'coin.png',
    // 'pacman/pacman_idle.png',
    // 'enemies/ghosts/ghost_blue.png',
    // 'enemies/ghosts/ghost_green.png',
    // 'enemies/ghosts/ghost_light_green.png',
    // 'enemies/ghosts/ghost_light_blue.png',
    // 'enemies/ghosts/ghost_pink.png',
    // 'enemies/ghosts/ghost_red.png'
  ]);

  runApp(Game());
}
