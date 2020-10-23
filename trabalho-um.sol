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
        address referee;
        string bet;
        bool accepted;
    }
    
    uint256 betId = 0;
    
    // pretendo passar a usar mapping
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
        address owner = msg.sender;
        betId += 1;
        bets[betId] = Bet({id: betId,
            ownerAmount: _amount,
            owner: _owner,
            participant: _participant,
            referee: _referee,
            bet: "spius",
            accepted: false
        });
        // para criar um endereço vazio: aaddress(0)
        return betId;
    }
    
    /**
     * @dev Cancels an unaccepted bet and return money to the creator
     * @param _betId - id of the bet to be cancelled
     */
    function cancel_bet(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(bet.owner == msg.sender && bet.accepted == false);
        // transfere o dinheiro de volta para o criador da bet
        bet.owner.transfer(bet.ownerAmount);
        delete bets[_betId];
    }
    
    /**
     * @dev Accepts a bet
     * @param _betId - id of the bet to be accepted
     */
    function accept_bet(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        require(bet.participant == msg.sender, "Você não é o participante dessa aposta");
        bet.accepted = true;
    }
    
    /**
     * @dev Define who has won the bet
     * @param _betId - id of the bet to be accepted
     * @param _winner - address of the winner account
     */
    function define_winner(uint256 _betId, address payable _winner) public {
        Bet storage bet = bets[_betId];
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

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}