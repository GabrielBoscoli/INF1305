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
        bool participant_accepted;
        address referee;
        bool referee_accepted;
        string bet;
    }
    
    uint256 betId = 0;
    
    mapping(uint256 => Bet) bets;
    
    /**
     * @dev Creates a bet with known participant and referee
     * @param _amount - of weis in the bet
     * @param _owner - address of the creator
     * @param _participant - address of the participant
     * @param _referee - address of the referee
     * @return id of the created bet
     */
    function create_bet(uint256 _amount, address payable _owner,
    address payable _participant, address _referee) payable public returns (uint256) {
        require(_amount == msg.value, "O valor depositado não confere");
        require(_owner == msg.sender, "O endereço do criador não é válido");
        require(_owner != _participant, "O criador da aposta não pode ser também o participante");
        betId += 1;
        bets[betId] = Bet({id: betId,
            ownerAmount: _amount,
            owner: _owner,
            participant: _participant,
            referee: _referee,
            bet: "spius",
            participant_accepted: false,
            referee_accepted: false
        });
        // para criar um endereço vazio: aaddress(0)
        return betId;
    }
    
    /**
     * @dev Creates a bet
     * @param _amount - of weis in the bet
     * @param _owner - address of the creator
     * @return id of the created bet
     */
    function create_bet(uint256 _amount, address payable _owner) payable public returns (uint256) {
        require(_amount == msg.value, "O valor depositado não confere");
        require(_owner == msg.sender, "O endereço do criador não é válido");
        betId += 1;
        bets[betId] = Bet({id: betId,
            ownerAmount: _amount,
            owner: _owner,
            participant: address(0),
            referee: address(0),
            bet: "spius",
            participant_accepted: false,
            referee_accepted: false
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
        require(bet.participant_accepted == false, "Essa aposta já foi aceita");
        // transfere o dinheiro de volta para o criador da bet
        bet.owner.transfer(bet.ownerAmount);
        delete bets[_betId];
    }
    
    /**
     * @dev Participant accepts a bet
     * @param _betId - id of the bet to be accepted
     */
    function participant_accept_bet(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        // se tiver um participante definido, ele deve ser o msg.sender
        if (bet.participant != address(0)) {
            require(bet.participant == msg.sender, "Você não é o participante dessa aposta");
        } else {
            // se nao tiver participante definido, o msg.sender passa a ser o participante
            require(bet.participant != bet.owner, "Você não pode ser o participante dessa aposta pois já é o criador dela");
            bet.participant = msg.sender;
        }
        bet.participant_accepted = true;
    }
    
    /**
     * @dev Referee accepts a bet
     * @param _betId - id of the bet to be accepted
     */
    function referee_accept_bet(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        // se tiver um juiz definido, ele deve ser o msg.sender
        if (bet.referee != address(0)) {
            require(bet.referee == msg.sender, "Você não é o juiz dessa aposta");
        } else {
            // se nao tiver juiz definido, o msg.sender passa a ser o juiz
            require(msg.sender != bet.owner && msg.sender != bet.participant, "O juiz não pode estar envolvido na aposta");
            bet.referee = msg.sender;
        }
        bet.referee_accepted = true;
    }
    
    /**
     * @dev Define who has won the bet
     * @param _betId - id of the bet to be accepted
     * @param _winner - address of the winner account
     */
    function define_winner(uint256 _betId, address payable _winner) public {
        Bet storage bet = bets[_betId];
        require(bet.referee == msg.sender, "Você não é o juiz dessa aposta");
        address owner = bet.owner;
        address participant = bet.participant;
        if (_winner == owner || _winner == participant) {
            _winner.transfer(bet.ownerAmount);
        }
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