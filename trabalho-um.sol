pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract BetContract {

    uint256 number;
    
    struct Bet {
        uint256 id;
        address owner;
        uint256 ownerAmount;
        address participant;
        address referee;
        string bet;
        bool accepted;
    }
    
    uint256 betId = 0;
    
    Bet[] public bets;
    
    function create_bet(uint256 amount, address participant, address referee) payable public {
        require(amount == msg.value, "O valor depositado não confere");
        address owner = msg.sender;
        betId += 1;
        Bet memory bet = Bet({id: betId, ownerAmount: amount, owner: owner, participant: participant, referee: referee, bet: "spius",
            accepted: false
        });
        bets.push(bet);
    }
    
    function cancel_bet(uint256 _betId) external {
        
    }
    
    function accept_bet(uint256 _betId) public {
        Bet storage bet = bets[_betId];
        require(bet.participant == msg.sender, "Você não é o participante dessa aposta");
        bet.accepted = true;
    }
    
    // transferir ether do contrato pro usuario: https://www.youtube.com/watch?v=_Nvl-gz-tRs&list=PLbbtODcOYIoE0D6fschNU4rqtGFRpk3ea&index=20
    function define_winner(uint256 _betId, address payable winner) public {
        Bet storage bet = bets[_betId];
        address owner = bet.owner;
        address participant = bet.participant;
        if (winner == owner || winner == participant) {
            winner.transfer(bet.ownerAmount);
        }
    }
    
    // external for functions that should not be used internally
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