import 'dart:math';
import 'dart:ui';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../poker99GameCtrl.dart';
// import '../pacman.dart';

class PCard extends Component {
  static Poker99GameCtrl GameCtrl = null;
  Sprite sprite = Sprite('poker1.png');

  Rect _playerRect;
  // PacMan _game;
  Point _position;
  Point _targetLocation;
  bool _died = false;
  int _points = 0;

  int id = 0;
  bool picking = false;
  int get points => _points;
  Point get position => _position;
  Rect get rect => _playerRect;
  bool get died => _died;

  set targetLocation(Point targetPoint) {
    _targetLocation = targetPoint;
  }

  String value;
  int decor;
  PCard(this.value, this.decor) {
    _position = Point(7.0, 10.0); // starting position

    _playerRect = Rect.fromLTWH(20, 20, 100, 150);
  }

  void die() {
    _position = null;
    _died = true;
    _points = 0;
  }

  execute(player) {}

  void render(Canvas canvas) {
    sprite.renderRect(canvas, _playerRect.inflate(2));
  }

  void update(double t) {}
}

class CardScore extends PCard {
  CardScore(String val, int decor) : super(val, decor) {}

  execute(player) {
    PCard.GameCtrl.score.add(int.parse(this.value));
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }

  executeTest(player) {
    // PPCard.GameCtrl.score.add(parseInt(this.value));
    // var fail = false;
    // if (PPCard.GameCtrl.score.get() > C.DeadlineScore) {
    //   fail = true;
    // }
    // PPCard.GameCtrl.score.restore();
    // return fail;
  }
}

class CardPlusMinus extends PCard {
  var scoreVal = 0;
  CardPlusMinus(String val, int decor, int score) : super(val, decor) {
    this.scoreVal = score;
  }
  execute(player) async {
    var toPlus =
        await PCard.GameCtrl.askToSelectPlusOrMinusScore(player, this.scoreVal);
    PCard.GameCtrl.score.add(toPlus ? this.scoreVal : -this.scoreVal);
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

class CardSteal extends PCard {
  CardSteal(String val, int decor) : super(val, decor) {}
  execute(player) async {
    var targetPlayer = await PCard.GameCtrl.askToSelectTargetPlayer(player);
    var a = targetPlayer.pickingCard();
    // PCard.GameCtrl.tick();
    // await sleep(1000);
    player.takeIn(a.card);
    // PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

class CardReverse extends PCard {
  CardReverse(String val, int decor) : super(val, decor) {}
  execute(player) async {
    PCard.GameCtrl.reversePlayOrder();
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

class CardExchange extends PCard {
  CardExchange(String val, int decor) : super(val, decor) {}
  execute(player) async {
    var targetPlayer = await PCard.GameCtrl.askToSelectTargetPlayer(player);
    // PCard.GameCtrl.getCardToPlayer(player);
    var c = targetPlayer.handCards;
    targetPlayer.handCards = player.handCards;
    player.handCards = c;
    super.execute(player);
  }
}

class CardScoreToTop extends PCard {
  CardScoreToTop(String val, int decor) : super(val, decor) {}
  execute(player) async {
    PCard.GameCtrl.score.set(C.DeadlineScore);
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

class CardPickNext extends PCard {
  CardPickNext(String val, int decor) : super(val, decor) {}
  execute(player) async {
    var targetPlayer = await PCard.GameCtrl.askToSelectTargetPlayer(player);
    PCard.GameCtrl.setNextPlayer(targetPlayer);
    PCard.GameCtrl.getCardToPlayer(player);
    super.execute(player);
  }
}

createCard(val, decor) {
  switch (val.toString()) {
    case 'A':
      return new CardPickNext(val, decor);
    case '3':
    case '4':
    case '5':
    case '6':
    case '9':
      return new CardScore(val, decor);
    case '10':
      return new CardPlusMinus(val, decor, 10);
    case 'Q':
      return new CardPlusMinus(val, decor, 20);
    case 'J':
      return new CardSteal(val, decor);
    case 'K':
      return new CardScoreToTop(val, decor);
    case '8':
      return new CardReverse(val, decor);
    case '7':
      return new CardExchange(val, decor);

    default:
      break;
  }
  return null;
}
