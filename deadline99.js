
class Card {

}
class CardScore {
    constructor(val) {
        this.val = val;
    }
    getName() {
        return this.val.toString();
    }
}
class CardPlusMinus {
    constructor(val) {
        this.val = val;
    }
    getName() {
        return this.val.toString();
    }
}
class CardSteal {
    constructor() {
    }
}
class CardReverse {

}
class CardExchange {

}
class CardToTop {

}
class CardPickNext {

}

class Card {
    constructor(val) {
        this.value = val;
    }


}

function createCard(val) {
    switch (val.toString()) {
        case '1':
            return new CardPickNext();
        case '3':
        case '4':
        case '5':
        case '6':
        case '9':
            return new CardScore(parseInt(val));
        case '10':
            return new CardPlusMinus(parseInt(val));
        case 'q':
            return new CardPlusMinus(parseInt(20));
        case 'j':
            return new CardSteal(parseInt(val));
        case 'k':
            return new CardToTop(parseInt(val));
        case '8':
            return new CardReverse(parseInt(val));
        case '7':
            return new CardExchange(parseInt(val));

        default:
            break;
    }
    return null;
}
class Score {
    constructor() {
        this.score = 0;
    }
    get() { return this.score; }
    add(plusValue) {
        this.score += plusValue;
    }
}

class GameCtrl {

    constructor() {
        this.score = new Score();
        this.players = [];
        this.cardStock = [];
        this.cardPlayed = [];
        this.myPlayer = null;
    }
    initRound() {

        for (var i = 0; i < 10; ++i) {
            this.cardStock.push(createCard(i));
            this.cardStock.push(createCard(i));
            this.cardStock.push(createCard(i));
            this.cardStock.push(createCard(i));
        }
        var arr = ['j', 'q', 'k'];
        for (const item of arr) {
            this.cardStock.push(createCard(item));
            this.cardStock.push(createCard(item));
            this.cardStock.push(createCard(item));
            this.cardStock.push(createCard(item));
        }
    }
    initPlayers(rivalNumber) {
        this.myPlayer = new Player();
        for (var i = 0; i < rivalNumber; ++i) {
            this.players.push(new Player());
        }

    }
    _pickCard() {
        let n = Math.random(this.cardStock.length - 1);
        let card = this.cardStock.splice(n, 1);
        return card;
    }
    dealCards() {
        for (var i = 0; i < 5; i++) {


            let a = _pickCard();
            myPlayer.takeIn(a);
            for (var j = 0; j < this.players.length; j++) {
                let b = _pickCard();

                this.players[j].takeIn(b);
            }
        }
    }

    renderCard(c) {

    }
    renderPlayer(p) {
        return 'Player: ' + p.handCards.map((c) => {
            return '*';
        }).join(' ') + '<br/>';
    }
    renderMyPlayer(p) {
        return 'Me    : ' + p.handCards.map((c) => {
            return renderCard(c);
        }).join(' ') + '<br/>';
    }
    render() {
        let tmpScore = '<BR/>$score$               '
        '<BR/> ';
        let tmpPlayerInfo = '$hideHandCards$';
        let hideCard = '*';
        let tmpPlayers = this.players.map((p) => {
            return this.renderPlayer(p);
        });
        let tmpPlayersHtml = tmpPlayers.join('<br/>');


        let html = '';
        html = tmpScore.replace('$score$', this.score.get());
        html += tmpPlayersHtml;
    }

    tick() {
        console.log('tick');
    }

    run(eleId) {
        this.initRound();
        this.initPlayers(4);
        setInterval(() => {
            this.tick();
        }, 1000);
    }

}

class Player {
    constructor() {
        this.handCards = [];
    }
    takeIn(card) {
        this.handCards.push(card);
    }
    playOut() {
        this.handCards;
    }
}