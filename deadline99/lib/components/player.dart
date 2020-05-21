import 'dart:math';
import 'dart:ui';
import 'package:Deadline99/defines.dart';
import 'package:Deadline99/utils/logger.dart';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../poker99GameCtrl.dart';
import 'card.dart';
// import '../pacman.dart';

class Player extends Component {
  Sprite spriteAvatar;
  static Poker99GameCtrl GameCtrl = null;

  Rect _playerRect;
  // PacMan _game;
  Point _position;
  Point _targetLocation;
  bool _died = false;
  int _points = 0;

  String name;
  int id;
  bool alive;
  List<PCard> handCards = [];
  bool isHost = false;

  int get points => _points;
  Point get position => _position;
  Rect get rect => _playerRect;
  bool get died => _died;

  set targetLocation(Point targetPoint) {
    _targetLocation = targetPoint;
  }

  Player(name, id, Offset center, bool isHost) {
    _position = Point(7.0, 10.0); // starting position

    _playerRect = Rect.fromCenter(
        center: center, width: AvatarWidth, height: AvatarHeight);
    this.isHost = isHost;
    this.name = name;
    this.id = id;
    this.alive = true;
    spriteAvatar = Sprite('avatar/' + id.toString() + '.png');
  }

  void die() {
    _position = null;
    _died = true;
    _points = 0;
  }

  getName() {
    return this.name;
  }

  takeIn(card) {
    card.picking = false;
    this.handCards.add(card);
  }

  moveCardOut(card) {
    this.handCards.remove(card);
  }

  playOutByID(id) {
    var card = this.handCards.firstWhere((c) {
      return c.id == id;
    });
    this.handCards.removeWhere((c) {
      return c.id == id;
    });
    return card;
  }

  playOut(card) {
    this.handCards.remove(card);
    return card;
  }

  pickingCard() {
    var n = Random().nextInt(this.handCards.length);
    var toPickCard = this.handCards[n];
    toPickCard.picking = true;
    return {'card': toPickCard, 'id': n};
  }

  pickCardOut(n) {
    var card = this.handCards.elementAt(n);
    card.picking = false;
    this.handCards.removeAt(n);
    return card;
  }

  setAlive(alive) {
    this.alive = alive;
  }

  isAlive() {
    return this.alive;
  }

  void render(Canvas canvas) {
    spriteAvatar.renderRect(canvas, _playerRect.inflate(1));
    this.handCards.forEach((c) {
      c.render(canvas);
    });
  }

  void update(double t) {
    var w = this.isHost ? CardWidth_Host : CardWidth;
    var h = this.isHost ? CardHeight_Host : CardHeight;
    var gap = w / (isHost ? 2.0 : 3.5);
    var gapNum = 2; //TODO
    var startPos =
        _playerRect.bottomCenter + Offset(0.0 - gap * gapNum - w / 2.0, 10);
    this.handCards.forEach((card) {
      card.setRect(startPos, width: w, height: h);
      startPos += Offset(gap, 0);
    });
  }

  bool onTapDown(TapDownDetails details) {
    if (!this.isAlive()) return false;
    if (this._playerRect.contains(details.globalPosition)) {
      console.log('onTapDown - player:' + getName());
      if (Player.GameCtrl.state == PState.SelectingTargetPlayer) {
        Player.GameCtrl.setTargetPlayer(this);
        Player.GameCtrl.callBackSelectedTargetPlayer(this);
      }
      return true;
    }
    bool isHandled = false;
    PCard clickedCard;
    this.handCards.reversed.forEach((card) {
      if (isHandled) {
        return;
      }
      if (card.rect.contains(details.globalPosition)) {
        clickedCard = card;
        isHandled = true;
      }
    });
    if (clickedCard != null) {
      console.log('onTapDown - card:' + clickedCard.getName());
      this.playOut(clickedCard);
      Player.GameCtrl.playCard(this, clickedCard);
      return true;
    }
    return false;
  }

  getId() {
    return this.id;
  }
}
