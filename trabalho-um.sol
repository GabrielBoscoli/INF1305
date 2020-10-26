pragma solidity >=0.4.22 <0.7.0;

/**
 * @title BetContract
 * @dev Create p2p bets and sends the reward to the winner
 */
contract BetContract {

    uint256 number;
    
    struct Bet {
        uint256 id;
        address payable owner;
        uint256 ownerAmount;
        address payable participant;
        uint256 participantAmount;
        bool participantAccepted;
        address payable referee;
        uint256 refereeTip;
        bool refereeAccepted;
        string betText;
    }
    
    uint256 betId = 0;
    
    mapping(uint256 => Bet) bets;
    
    /**
     * @dev Creates a bet with known participant and referee
     * @param _betText - statement of the bet. if is true, the bet crator wins
     * @param _amount - of weis in the bet
     * @param _owner - address of the bet creator
     * @param _participant - address of the participant
     * @param _participantAmount - amount of money that the participant needs to bet in order to participate
     * @param _referee - address of the referee
     * @param _refereeTip - tip to encourage a referee to accept your bet. it is going to be subtracted of "_amount"
     * @return id of the created bet
     */
    function create_bet(string memory _betText, uint256 _amount, address payable _owner,
    address payable _participant, uint256 _participantAmount, address payable _referee, uint256 _refereeTip) payable public returns (uint256) {
        require(_amount == msg.value, "O valor depositado não confere");
        require(_owner == msg.sender, "O endereço do criador não é válido");
        require(_owner != _participant, "O criador da aposta não pode ser também o participante");
        betId += 1;
        bets[betId] = Bet({id: betId,
            ownerAmount: _amount - _refereeTip,
            owner: _owner,
            participant: _participant,
            referee: _referee,
            refereeTip: _refereeTip,
            betText: _betText,
            participantAccepted: false,
            participantAmount: _participantAmount,
            refereeAccepted: false
        });
        return betId;
    }
    
    /**
     * @dev Creates a bet with unknown participant and referee
     * @param _betText - statement of the bet. if is true, the bet crator wins
     * @param _amount - of weis in the bet
     * @param _owner - address of the bet creator
     * @param _participantAmount - amount of money that the participant needs to bet in order to participate
     * @param _refereeTip - tip to encourage a referee to accept your bet
     * @return id of the created bet
     */
    function create_bet(string memory _betText, uint256 _amount, address payable _owner, uint256 _participantAmount, uint256 _refereeTip) payable public returns (uint256) {
        require(_amount == msg.value, "O valor depositado não confere");
        require(_owner == msg.sender, "O endereço do criador não é válido");
        betId += 1;
        bets[betId] = Bet({id: betId,
            ownerAmount: _amount - _refereeTip,
            owner: _owner,
            participant: address(0),
            referee: address(0),
            refereeTip: _refereeTip,
            betText: _betText,
            participantAccepted: false,
            participantAmount: _participantAmount,
            refereeAccepted: false
        });
        return betId;
    }
    
    /**
     * @dev Cancels an unaccepted bet and return money to the creator
     * @param _betId - id of the bet to be cancelled
     */
    function cancel_bet(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(bet.owner == msg.sender, "Você não é o criador da aposta");
        require(bet.participantAccepted == false, "Essa aposta já foi aceita");
        // transfere o dinheiro de volta para o criador da bet
        bet.owner.transfer(bet.ownerAmount);
        delete bets[_betId];
    }
    
    /**
     * @dev Participant accepts a bet
     * @param _betId - id of the bet to be accepted
     */
    function participant_accept_bet(uint256 _betId) payable public {
        Bet storage bet = bets[_betId];
        require(msg.value == bet.participantAmount, "Valor pago não confere");
        // se tiver um participante definido, ele deve ser o msg.sender
        if (bet.participant != address(0)) {
            require(bet.participant == msg.sender, "Você não é o participante dessa aposta");
        } else {
            // se nao tiver participante definido, o msg.sender passa a ser o participante
            require(bet.participant != bet.owner, "Você não pode ser o participante dessa aposta pois já é o criador dela");
            bet.participant = msg.sender;
        }
        bet.participantAccepted = true;
    }
    
    /**
     * @dev Referee accepts a bet
     * @param _betId - id of the bet to be accepted
     * @param _refereeWarranty - amount referee deposits in good faith
     * needs to be exactly the same amout as the owner bet and it is returned once the bet winner is defined
     */
    function referee_accept_bet(uint256 _betId, uint256 _refereeWarranty) payable public {
        Bet storage bet = bets[_betId];
        require(bet.ownerAmount == _refereeWarranty, "A garantia não possui o valor adequado");
        require(msg.value == _refereeWarranty, "O valor depositado não confere");
        // se tiver um juiz definido, ele deve ser o msg.sender
        if (bet.referee != address(0)) {
            require(bet.referee == msg.sender, "Você não é o juiz dessa aposta");
        } else {
            // se nao tiver juiz definido, o msg.sender passa a ser o juiz
            require(msg.sender != bet.owner && msg.sender != bet.participant, "O juiz não pode estar envolvido na aposta");
            bet.referee = msg.sender;
        }
        bet.refereeAccepted = true;
    }
    
    /**
     * @dev Define who has won the bet
     * @param _betId - id of the bet to be accepted
     * @param _winner - address of the winner account or 0, if bet results in a draw
     */
    function define_winner(uint256 _betId, address payable _winner) public {
        Bet storage bet = bets[_betId];
        require(bet.referee == msg.sender, "Você não é o juiz dessa aposta");
        address owner = bet.owner;
        address participant = bet.participant;
        if (_winner == owner || _winner == participant) {
            _winner.transfer(bet.ownerAmount);
        } else if (_winner == address(0)) {
            // se ocorrer um empate, o dinheiro de cada envolvido na aposta volta
            bet.owner.transfer(bet.ownerAmount);
            bet.participant.transfer(bet.participantAmount);
        }
        // referee get his tip and his warranty back
        bet.referee.transfer(bet.refereeTip);
        bet.referee.transfer(bet.ownerAmount);
    }
    
    // external for functions that should not be used internally
    /**
     * @dev Return balance
     * @return balance of this contract
     */
    function check_contract_balance() external view returns (uint256){
        return address(this).balance;
    }
}