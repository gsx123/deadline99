
async function sleep(time = 0) {
    return await new Promise((resolve, reject) => {
        setTimeout(() => {
            resolve();
        }, time);
    });
}

let obj = {};
class EventEmitter {
    on = (name, fn) => {
        if (!obj[name]) {
            obj[name] = [];
        }
        obj[name].push(fn);
    }

    emit = (name, val) => {
        if (obj[name]) {
            obj[name].map((fn) => {
                fn(val);
            });
        }
    }

    off = (name, fn) => {
        if (obj[name]) {
            if (fn) {
                let index = obj[name].indexOf(fn);
                if (index > -1) {
                    obj[name].splice(index, 1);
                }
            } else {
                obj[name].length = 0;
                //设长度为0比obj[name] = []更优，因为如果是空数组则又开辟了一个新空间，设长度为0则不必开辟新空间
            }
        }
    }
}

let C = {
    HandSize: 5,
    DeadlineScore: 99,
}
class Card {
    static CardID = 0;
    static GameCtrl = null;
    static imageCovered = 'assets/image/poker/covered.jpg';
    constructor(val, decor) {
        this.value = val;
        this.id = Card.CardID++;
        this.picking = false;
        this.image = 'assets/image/poker/' + val.toString() + (decor == 1 ? '' : ' (' + decor.toString() + ')') + '.jpg';
    }

    getName() {
        return this.value.toString();
    }
    async execute(player) {

        Card.GameCtrl.eventEmitter.emit('judge', player);

    }
}
class CardScore extends Card {
    constructor(val, decor) {
        super(val, decor);
    }

    async execute(player) {
        Card.GameCtrl.score.add(parseInt(this.value));
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardPlusMinus extends Card {
    constructor(val, decor, scoreVal) {
        super(val, decor);
        this.scoreVal = scoreVal;
    }
    async execute(player) {
        let toPlus = await Card.GameCtrl.askToSelectPlusOrMinusScore(player, this.scoreVal);
        Card.GameCtrl.score.add(toPlus ? this.scoreVal : -this.scoreVal);
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardSteal extends Card {
    constructor(val, decor) {
        super(val, decor);
    }
    async execute(player) {
        let targetPlayer = await Card.GameCtrl.askToSelectTargetPlayer(player);
        let { card, id } = targetPlayer.pickingCard();
        Card.GameCtrl.tick();
        await sleep(1000);
        player.takeIn(card);
        // Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardReverse extends Card {
    constructor(val, decor) {
        super(val, decor);
    }
    async execute(player) {

        Card.GameCtrl.reversePlayOrder();
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardExchange extends Card {
    constructor(val, decor) {
        super(val, decor);
    }
    async execute(player) {
        let targetPlayer = await Card.GameCtrl.askToSelectTargetPlayer(player);
        // Card.GameCtrl.getCardToPlayer(player);
        let c = targetPlayer.handCards;
        targetPlayer.handCards = player.handCards;
        player.handCards = c;
        super.execute(player);
    }
}
class CardScoreToTop extends Card {
    constructor(val, decor) {
        super(val, decor);
    }
    async execute(player) {
        Card.GameCtrl.score.set(C.DeadlineScore);
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}
class CardPickNext extends Card {
    constructor(val, decor) {
        super(val, decor);
    }
    async execute(player) {
        let targetPlayer = await Card.GameCtrl.askToSelectTargetPlayer(player);
        Card.GameCtrl.setNextPlayer(targetPlayer);
        Card.GameCtrl.getCardToPlayer(player);
        super.execute(player);
    }
}



function createCard(val, decor) {
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
class Score {
    constructor() {
        this.score = 0;
        this.scoreBackup = 0;
    }
    get() { return this.score; }
    set(s) { this.scoreBackup = this.score; this.score = s; }
    add(plusValue) {
        this.scoreBackup = this.score;
        this.score += plusValue;
    }
    restore() {
        this.score = this.scoreBackup;
    }
}

var State = {
    Init: 0,
    BuildHands: 1,

}

// var EventEmitter = require('events').EventEmitter

class GameCtrl {

    constructor() {
        this.eventEmitter = new EventEmitter();
        this.score = new Score();
        this.players = [];
        this.cardStock = [];
        this.cardPlayed = [];
        this.cardRecyle = [];
        this.myPlayer = null;
        this.tickCnt = 0;
        this.state = State.init;
        this.renderDomId = '';
        this.targetPlayer = null;

        this.playOrderClockwise = true;
        this.specifiedNextPlayerId = -1;
        this.curPlayerId = 0;

        this.rivalNumber = 4;
    }
    initGame() {

        this.eventEmitter.on('judge', async (player) => {
            console.log('onEvent judge');

            let lose = false;
            if (player.handCards.length == 0) {
                lose = true;
            }
            if (this.score.get() > C.DeadlineScore) {
                lose = true;
                this.score.restore();
            }
            if (lose) {
                player.setAlive(false);
            }

            let aliveCnt = this.myPlayer.isAlive() ? 1 : 0;
            let alivePlayer = aliveCnt == 1 ? this.myPlayer : null;
            for (const p of this.players) {
                aliveCnt += p.isAlive() ? 1 : 0;
                if (!alivePlayer) alivePlayer = p.isAlive() ? p : null;
            }
            if (aliveCnt == 1) {
                console.log('GameOver only one alive');
                this.onEndARound(alivePlayer);
            } else {
                this.eventEmitter.emit('nextPlayer');
            }

        })
        this.eventEmitter.on('nextPlayer', async () => {
            console.log('onEvent nextPlayer');
            let np = this.getNextPlayer();
            await sleep(1000);
            if (this.isMyPlayer(np)) {

                return;
            }
            // let card = np.pickCard();
            // this.playCard(np, card);
            await this.pickingPlayCard(np);
        })

        this.state = State.init;
        for (var i = 3; i <= 10; ++i) {
            this.cardStock.push(createCard(i, 1));
            this.cardStock.push(createCard(i, 2));
            this.cardStock.push(createCard(i, 3));
            this.cardStock.push(createCard(i, 4));
        }
        var arr = ['A', 'J', 'Q', 'K'];
        for (const item of arr) {
            this.cardStock.push(createCard(item, 1));
            this.cardStock.push(createCard(item, 2));
            this.cardStock.push(createCard(item, 3));
            this.cardStock.push(createCard(item, 4));
        }
    }

    initPlayers(rivalNumber) {
        this.myPlayer = new Player('Me', 0);
        for (var i = 0; i < rivalNumber; ++i) {
            this.players.push(new Player(i.toString(), i + 1));
        }

    }

    onEndARound(winner) {
        window.alert('Winer is ' + winner.getName());

        this.reloadARound();
    }
    resetPlayer(player) {
        this.cardRecyle.contat(player.handCards);
        player.handCards = []; player.setAlive(true);
    }

    reloadARound() {
        console.warn('==== reloadARound');
        this.cardRecyle = this.cardPlayed;
        this.cardPlayed = [];
        this.myPlayer.setAlive(true);
        this.resetPlayer(this.myPlayer);
        this.players.forEach((e) => {
            this.resetPlayer(e);
        });
    }
    _pickCard() {
        if (this.cardStock.length == 0) {
            console.info('No card in stock ,reload ');
            this.cardStock = this.cardRecyle;
            this.cardRecyle = [];
        }
        let n = Math.floor(Math.random() * this.cardStock.length);
        let card = this.cardStock.splice(n, 1)[0];

        return card;
    }

    setNextPlayer(player) {
        for (let i = 0; i < this.players.length; ++i) {
            if (player == this.players[i]) {
                this.specifiedNextPlayerId = i + 1;
            }
        }
        if (player == this.myPlayer) {
            this.specifiedNextPlayerId = 0;
        }
        console.log(`setNextPlayer specify id:${this.specifiedNextPlayerId}`);
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
            console.log(`getNextPlayer id:${this.curPlayerId}`);
            if (this.curPlayerId == 0) {
                if (!this.myPlayer.isAlive()) {
                    console.error('Me dead');
                    continue;
                }
                this.tick();
                return this.myPlayer;
            }
            let testPlayer = this.players[this.curPlayerId - 1];
            if (!testPlayer.isAlive()) {
                console.log(`getNextPlayer player:${testPlayer.getName()} dead`);
                continue;
            }
            return testPlayer;
        } while (true);

    }
    reversePlayOrder() {
        this.playOrderClockwise = !this.playOrderClockwise;

    }

    getCardToPlayer(player) {
        let a = this._pickCard();
        player.takeIn(a);
        console.log(`getCardToPlayer card:${a.getName()} player:${player.getName()}`);
    }
    recvPlayedCard(card) {
        this.cardPlayed.push(card);
    }
    setTargetPlayer(player) {
        this.targetPlayer = player;
    }
    getTargetPlayer() {
        return this.targetPlayer;
    }
    async buildHands() {
        console.log('buildHands');
        this.state = State.BuildHands;
        for (var i = 0; i < C.HandSize; i++) {

            await sleep(1000);
            let a = this._pickCard();
            this.myPlayer.takeIn(a);
            for (var j = 0; j < this.players.length; j++) {
                let b = this._pickCard();

                this.players[j].takeIn(b);
            }
            this.tick();
        }
    }
    async initRound() {
        await this.buildHands();
    }

    isMyPlayer(player) {
        return player.getName() == this.myPlayer.getName();
    }
    async askToSelectPlusOrMinusScore(player, score) {
        if (!this.isMyPlayer(player)) {
            let toPlus = Math.round(Math.random()) == 1;
            console.log('askToSelectPlusOrMinusScore[auto]: ' + toPlus ? 'plus' : 'minus');
            return toPlus;
        }
        let toPlus = await window.confirm(`plus or minus ${score}`);
        console.log('askToSelectPlusOrMinusScore: ' + toPlus ? 'plus' : 'minus');
        return toPlus;
    }
    async askToSelectTargetPlayer(player) {
        if (!this.isMyPlayer(player)) {
            let arr = [];
            for (const item of this.players) {
                if (item.isAlive() && player.getId() != item.getId()) arr.push(item);
            }
            arr.push(this.myPlayer);
            let id = Math.floor(Math.random() * arr.length);
            this.targetPlayer = arr[id];
            console.log(`askToSelectTargetPlayer[auto] selected:${this.targetPlayer.getName()}`)
            return this.targetPlayer;
        }
        window.alert('select a player to apply your magic');
        document.getElementsByClassName('player');
        this.targetPlayer = null;

        while (true) {
            await sleep(100);
            console.log('askToSelectTargetPlayer waiting');
            if (this.targetPlayer) {
                break;
            }
        }
        console.log(`askToSelectTargetPlayer selected:${this.targetPlayer.getName()}`)
        return this.targetPlayer;
    }

    async pickingPlayCard(player) {
        let picking = player.pickingCard();
        this.tick();
        await sleep(2000);
        player.pickCardOut(picking.id);
        this.playCard(player, picking.card);

        this.tick();
    }
    playCard(player, card) {
        if (card) {
            console.warn(`[playCard] "${player.getName()}" played ${card.getName()}`);
            this.recvPlayedCard(card);
            card.execute(player);
            this.tick();
        }
        // gt.tick();
    }

    renderGetPos(xpos) {
        let css = 'position: absolute;left: ' + xpos + 'px;top: 2px';
        return css;
    }

    renderPiledCards(images) {
        let html = '';
        let gap = 20;
        for (let index = 0; index < images.length; index++) {
            const img = images[index];
            let xpos = index * gap;
            html += '<img style="' + this.renderGetPos(xpos) + '" src="' + img + '"/>';
        }
        return html;
    }

    renderCoveredCard() {
        return '<img src="' + Card.imageCovered + '"/>';
    }
    renderCard(c) {
        return '<img src="' + c.image + '"/>';
        // return c.getName();
    }
    renderCardClickable(c) {
        return '<button class=player onclick="playCard(' + c.id + ')">' + this.renderCard(c) + '</button>';
    }
    renderPlayer(p, curPlayerId) {
        if (!p.isAlive()) {
            return '<s>Player ' + p.getName() + '</s>';
        }
        let color = curPlayerId == p.id ? 'red' : 'black';
        return '<button style="color:' + color + '" onclick="selectPlayer(\'' + p.getName() + '\')">Player ' + p.getName() + '</button> : ' + p.handCards.map((c) => {
            return c.picking ? this.renderCard(c) : this.renderCoveredCard();
        }).join(' ') + '<br/>';
    }
    renderMyPlayer(p, curPlayerId) {
        if (!p.isAlive()) {
            return '<s>Me</s>';
        }
        let color = curPlayerId == p.id ? 'red' : 'black';
        return '<span style="color:' + color + '">Me</span>    : ' + p.handCards.map((c) => {
            return this.renderCardClickable(c);
        }).join(' ') + '<br/>';
    }
    renderCardStock() {
        let imgs = this.cardStock.map((c) => { return c.image });
        return '<div>' + this.renderPiledCards(imgs) + '</div>';
        // return '<div>' + this.renderCoveredCard().repeat(this.cardStock.length) + '</div>';
    }
    renderCardPlayed() {
        return 'Played    : ' + this.cardPlayed.map((c) => {
            return this.renderCard(c);
        }).join(' ') + '<br/>';
    }
    render() {
        let eleId = this.renderDomId;
        let tmpTick = '<BR/>tic : $tick$ ';
        let tmpScore = '<BR/>score: $score$               '
        '<BR/> ';
        let tmpPlayerInfo = '$hideHandCards$';
        let hideCard = '*';
        let tmpPlayers = this.players.map((p) => {
            return this.renderPlayer(p, this.curPlayerId);
        });
        let tmpPlayersHtml = tmpPlayers.join('<br/>');

        let tmpMy = this.renderMyPlayer(this.myPlayer, this.curPlayerId);

        let html = '';

        let htmlTick = tmpTick.replace('$tick$', this.tickCnt);
        html = htmlTick;
        html += tmpScore.replace('$score$', this.score.get());
        html += '<hr/>';
        html += this.renderCardStock();
        html += '<hr/>';
        html += this.renderCardPlayed();
        html += '<hr/>';
        html += tmpPlayersHtml;
        html += '<hr/>';
        html += tmpMy;

        document.getElementById(eleId).innerHTML = html;
    }

    tick() {
        // console.log('tick');
        this.tickCnt++;
        this.render();
    }

    run(eleId) {
        this.initGame();
        this.initPlayers(this.rivalNumber);
        this.initRound();
        this.renderDomId = eleId;
        let the = this;
        setInterval(() => {
            // the.tick(eleId);
        }, 1000);

    }

}

class Player {
    constructor(name, id) {
        this.handCards = [];
        this.name = name;
        this.id = id;
        this.alive = true;
    }
    getId() { return this.id; }
    getName() {
        return this.name;
    }
    takeIn(card) {
        card.picking = false;
        this.handCards.push(card);
    }
    moveCardOut(card) {
        let index = this.handCards.findIndex((c) => { return card.id == c.id; });
        this.handCards.splice(index, 1);

    }
    playOutByID(id) {
        let card = this.handCards.find((c) => { return c.id == id; });
        if (card) {
            this.moveCardOut(card);
        } else {
            console.error('playOutByID not found card:' + id);
        }
        return card;
    }
    pickingCard() {
        let n = Math.floor(Math.random() * this.handCards.length);
        let toPickCard = this.handCards[n];
        toPickCard.picking = true;
        return { card: toPickCard, id: n };
    }
    pickCardOut(n) {
        let card = this.handCards.splice(n, 1)[0];
        card.picking = false;
        return card;
    }
    setAlive(alive) {
        this.alive = alive;
    }
    isAlive() { return this.alive; }
}

var gt = new GameCtrl();
Card.GameCtrl = gt;
function getGameCtrl() {
    return gt;
}
function playCard(id) {
    let card = gt.myPlayer.playOutByID(id);
    gt.playCard(gt.myPlayer, card);
}


function selectPlayer(name) {
    let player = gt.players.find((c) => { return c.name == name; });

    console.log('selectPlayer ' + player.getName());
    gt.setTargetPlayer(player);
}