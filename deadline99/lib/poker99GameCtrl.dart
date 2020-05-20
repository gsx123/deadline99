import 'dart:math';
import 'dart:ui';
import 'package:Deadline99/poker99.dart';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import 'components/card.dart';
import 'components/player.dart';
// import '../pacman.dart';

class Poker99GameCtrl extends Component {
  Sprite sprite = Sprite('poker1.png');

  Rect _playerRect;
  // PacMan _game;
  Point _position;
  Point _targetLocation;
  bool _died = false;
  int _points = 0;

  int get points => _points;
  Point get position => _position;
  Rect get rect => _playerRect;
  bool get died => _died;

  Poker99 game;
  Player myPlayer;
  List<Player> players = List();
  List<PCard> cardStock = List();
  List<PCard> cardPlayed = List();
  List<PCard> cardRecyle = List();

  Poker99GameCtrl(this.game) {
    _position = Point(7.0, 10.0); // starting position

    _playerRect = Rect.fromLTWH(20, 20, 100, 150);

    initPlayers(3);
  }

  void die() {
    _position = null;
    _died = true;
    _points = 0;
  }

  initCards() {
    for (var i = 3; i <= 10; ++i) {
      this.cardStock.add(createCard(i, 1));
      this.cardStock.add(createCard(i, 2));
      this.cardStock.add(createCard(i, 3));
      this.cardStock.add(createCard(i, 4));
    }
    var arr = ['A', 'J', 'Q', 'K'];
    for (var item in arr) {
      this.cardStock.add(createCard(item, 1));
      this.cardStock.add(createCard(item, 2));
      this.cardStock.add(createCard(item, 3));
      this.cardStock.add(createCard(item, 4));
    }
  }

  initPlayers(rivalNumber) {
    var marginH = 100.0;
    var marginV = 100.0;
    var center = Offset(
        this.game.screenSize.width / 2, this.game.screenSize.height - marginV);
    this.myPlayer = new Player('Me', 0, center);
    var leftCenter = Offset(marginH, this.game.screenSize.height / 2);
    var leftTop = Offset(marginH, marginV);
    var topCenter = Offset(this.game.screenSize.width / 2, marginV);
    var rightTop = Offset(this.game.screenSize.width - marginH, marginV);
    var rightCenter = Offset(
        this.game.screenSize.width - marginH, this.game.screenSize.height / 2);
    List<Offset> posarr = [];
    switch (rivalNumber) {
      case 1:
        posarr.add(topCenter);
        break;
      case 2:
        posarr.add(leftCenter);
        posarr.add(rightCenter);
        break;
      case 3:
        posarr = [leftCenter, topCenter, rightCenter];
        break;
      case 4:
        posarr = [leftCenter, leftTop, rightTop, rightCenter];
        break;
      case 5:
        posarr = [leftCenter, leftTop, topCenter, rightTop, rightCenter];
        break;
      default:
    }
    for (var i = 0; i < rivalNumber; ++i) {
      this.players.add(new Player(i.toString(), i + 1, posarr[i]));
    }
  }

  void render(Canvas canvas) {
    myPlayer.render(canvas);

    if (cardStock.length > 0) {
      cardStock.forEach((coin) {
        coin.render(canvas);
      });
    }
    cardPlayed.forEach((coin) {
      coin.render(canvas);
    });
    players.forEach((coin) {
      coin.render(canvas);
    });
  }

  void update(double t) {
    myPlayer.update(t);

    players.forEach((ghost) {
      ghost.update(t);
    });
    cardStock.forEach((ghost) {
      ghost.update(t);
    });

    cardPlayed.forEach((coin) {
      coin.update(t);
    });

    // Remove coins consumed
    // if(_coinsToRemove.isNotEmpty) {
    //   _coins.removeWhere((coin) => _coinsToRemove.contains(coin));
    //   _coinsToRemove.clear();
    // }
  }
}
