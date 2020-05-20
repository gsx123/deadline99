import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:Deadline99/poker99.dart';
import 'package:flame/components/component.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import 'components/card.dart';
import 'components/player.dart';

// import '../pacman.dart';
class C {
  static int HandSize = 5;
  static int DeadlineScore = 99;
}

class Logger {
  warn(msg) {
    print(msg);
  }

  info(msg) {
    print(msg);
  }

  log(msg) {
    print(msg);
  }

  error(msg) {
    print(msg);
  }
}

class Score {
  var score = 0;
  var scoreBackup = 0;
  get() {
    return this.score;
  }

  set(s) {
    this.scoreBackup = this.score;
    this.score = s;
  }

  add(plusValue) {
    this.scoreBackup = this.score;
    this.score += plusValue;
  }

  restore() {
    this.score = this.scoreBackup;
  }
}

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

  int tickCnt = 0;
  // this.state = State.init;
  Player targetPlayer = null;

  bool playOrderClockwise = true;
  int specifiedNextPlayerId = -1;
  int curPlayerId = 0;

  int rivalNumber = 4;

  Logger console = Logger();
  Score score = Score();
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

  onEndARound(winner) {
    // window.alert('Winer is ' + winner.getName());

    this.reloadARound();
  }

  reloadARound() {
    console.warn('==== reloadARound');
    this.cardRecyle = this.cardPlayed;
    this.cardPlayed = [];
    this.myPlayer.setAlive(true);
    this.resetPlayer(this.myPlayer);
    this.players.forEach((e) {
      this.resetPlayer(e);
    });
  }

  resetPlayer(player) {
    this.cardRecyle.addAll(player.handCards);
    player.handCards = [];
    player.setAlive(true);
  }

  _pickCard() {
    if (this.cardStock.length == 0) {
      console.info('No card in stock ,reload ');
      this.cardStock = this.cardRecyle;
      this.cardRecyle = [];
    }
    var n = Random().nextInt(this.cardStock.length);
    var card = this.cardStock[n];

    return card;
  }

  setNextPlayer(player) {
    for (var i = 0; i < this.players.length; ++i) {
      if (player == this.players[i]) {
        this.specifiedNextPlayerId = i + 1;
      }
    }
    if (player == this.myPlayer) {
      this.specifiedNextPlayerId = 0;
    }
    console.log('setNextPlayer specify id:${this.specifiedNextPlayerId}');
  }

  getNextPlayer() {
    if (this.specifiedNextPlayerId >= 0) {
      this.curPlayerId = this.specifiedNextPlayerId;
      this.specifiedNextPlayerId = -1;
      if (this.curPlayerId == 0) {
        return this.myPlayer;
      }
      return this.players[this.curPlayerId - 1];
    }
    do {
      this.playOrderClockwise ? this.curPlayerId++ : this.curPlayerId--;
      if (this.curPlayerId > this.players.length) {
        this.curPlayerId = 0;
      }
      if (this.curPlayerId < 0) {
        this.curPlayerId = this.players.length;
      }
      console.log('getNextPlayer id:${this.curPlayerId}');
      if (this.curPlayerId == 0) {
        if (!this.myPlayer.isAlive()) {
          console.error('Me dead');
          continue;
        }
        // this.tick();
        return this.myPlayer;
      }
      var testPlayer = this.players[this.curPlayerId - 1];
      if (!testPlayer.isAlive()) {
        console.log('getNextPlayer player:${testPlayer.getName()} dead');
        continue;
      }
      return testPlayer;
    } while (true);
  }

  reversePlayOrder() {
    this.playOrderClockwise = !this.playOrderClockwise;
  }

  getCardToPlayer(player) {
    var a = this._pickCard();
    player.takeIn(a);
    console
        .log('getCardToPlayer card:${a.getName()} player:${player.getName()}');
  }

  recvPlayedCard(card) {
    this.cardPlayed.add(card);
  }

  setTargetPlayer(player) {
    this.targetPlayer = player;
  }

  getTargetPlayer() {
    return this.targetPlayer;
  }

  buildHands() async {
    console.log('buildHands');
    // this.state = State.BuildHands;
    for (var i = 0; i < C.HandSize; i++) {
      sleep(Duration(seconds: 1));
      var a = this._pickCard();
      this.myPlayer.takeIn(a);
      for (var j = 0; j < this.players.length; j++) {
        var b = this._pickCard();

        this.players[j].takeIn(b);
      }
      // this.tick();
    }
  }

  initRound() async {
    await this.buildHands();
  }

  isMyPlayer(player) {
    return player.getName() == this.myPlayer.getName();
  }

  pickingPlayCard(player) async {
    var picking = player.pickingCard();
    // this.tick();
    // await sleep(2000);
    player.pickCardOut(picking.id);
    this.playCard(player, picking.card);

    // this.tick();
  }

  playCard(player, card) {
    if (card) {
      console.warn('[playCard] "${player.getName()}" played ${card.getName()}');
      this.recvPlayedCard(card);
      card.execute(player);
      // this.tick();
    }
    // gt.tick();
  }

  askToSelectPlusOrMinusScore(player, score) async {}
  askToSelectTargetPlayer(player) async {}

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
