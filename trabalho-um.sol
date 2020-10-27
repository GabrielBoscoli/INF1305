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
        uint256 refereeDeadline;
        string betText;
    }
    
    uint256 betId = 0;
    
    mapping(uint256 => Bet) public bets;
    
    /**
     * @dev Creates a bet with known participant and referee
     * @param _betText - statement of the bet. if is true, the bet crator wins
     * @param _amount - of weis in the bet
     * @param _owner - address of the bet creator
     * @param _participant - address of the participant
     * @param _participantAmount - amount of money that the participant needs to bet in order to participate
     * @param _referee - address of the referee
     * @param _refereeTip - tip to encourage a referee to accept your bet. it is going to be subtracted of "_amount"
     * @param _refereeDeadline - maximum days in which the referee decision should be made
     * @return id of the created bet
     */
    function createBetWithParticipant(string memory _betText, uint256 _amount, address payable _owner,
    address payable _participant, uint256 _participantAmount, address payable _referee, uint256 _refereeTip, uint256 _refereeDeadline) payable public returns (uint256) {
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
            refereeAccepted: false,
            refereeDeadline: now + (_refereeDeadline * 1 days)
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
     * @param _refereeDeadline - maximum days in which the referee decision should be made
     * @return id of the created bet
     */
    function createBet(string memory _betText, uint256 _amount, address payable _owner, uint256 _participantAmount, uint256 _refereeTip, uint256 _refereeDeadline) payable public returns (uint256) {
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
            refereeAccepted: false,
            refereeDeadline: now + (_refereeDeadline * 1 days)
        });
        return betId;
    }
    
    /**
     * @dev Cancels an unaccepted bet and return money to the creator
     * @param _betId - id of the bet to be cancelled
     */
    function cancelBet(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(bet.owner == msg.sender, "Você não é o criador da aposta");
        require(bet.participantAccepted == false || bet.refereeAccepted == false, "Essa aposta não pode ser cancelada");
        // transfere o dinheiro de volta para o criador da bet
        bet.owner.transfer(bet.ownerAmount + bet.refereeTip);
        // trasfere o dinheiro de volta para o juiz, caso ele tenha aceitado a bet
        if (bet.refereeAccepted == true) {
            bet.referee.transfer(bet.ownerAmount);
        }
        // transfere o dinheiro de volta para o participante, caso tenha aceitado a bet
        if (bet.participantAccepted == true) {
            bet.participant.transfer(bet.participantAmount);
        }
        delete bets[_betId];
    }
    
    /**
     * @dev Participant accepts a bet
     * @param _betId - id of the bet to be accepted
     */
    function participantAcceptBet(uint256 _betId) payable external {
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
     * @dev Participant decline a bet
     * @param _betId - id of the bet to be declined
     */
    function participantDeclineBet(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(msg.sender == bet.participant, "Você não é o participante da aposta");
        require(bet.participantAccepted == false || bet.refereeAccepted == false, "Você não pode sair dessa aposta");
        // transfere o dinheiro de volta para o participante, caso ele tenha aceitado
        if (bet.participantAccepted == true) {
            bet.participant.transfer(bet.participantAmount);
        }
        // tira os dados do participant da aposta
        bet.participant = address(0);
        bet.participantAccepted == false;
    }
    
    /**
     * @dev Referee accepts a bet
     * @param _betId - id of the bet to be accepted
     * @param _refereeWarranty - amount referee deposits in good faith
     * needs to be exactly the same amout as the owner bet and it is returned once the bet winner is defined
     */
    function refereeAcceptBet(uint256 _betId, uint256 _refereeWarranty) payable external {
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
     * @dev Referee decline a bet
     * @param _betId - id of the bet to be declined
     */
    function refereeDeclineBet(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(msg.sender == bet.referee, "Você não é o juiz da aposta");
        require(bet.refereeAccepted == false || bet.participantAccepted == false, "Você não pode sair dessa aposta");
        // transfere a garantia de volta para o juiz, caso ele tenha aceitado a aposta
        if (bet.refereeAccepted == true) {
            bet.referee.transfer(bet.ownerAmount);
        }
        // tira os dados do juiz da aposta
        bet.referee = address(0);
        bet.refereeAccepted == false;
    }
    
    /**
     * @dev Define who has won the bet
     * @param _betId - id of the bet
     * @param _winner - address of the winner account or 0, if bet results in a draw
     */
    function defineWinner(uint256 _betId, address payable _winner) external {
        Bet storage bet = bets[_betId];
        require(bet.referee == msg.sender, "Você não é o juiz dessa aposta");
        require(bet.participantAccepted == true, "O participante ainda não aceitou a aposta");
        address owner = bet.owner;
        address participant = bet.participant;
        require(_winner == owner || _winner == participant || _winner == address(0), "Endereço inválido");
        if (_winner == owner || _winner == participant) {
            _winner.transfer(bet.ownerAmount + bet.participantAmount);
        } else if (_winner == address(0)) {
            // se ocorrer um empate, o dinheiro de cada envolvido na aposta volta
            bet.owner.transfer(bet.ownerAmount);
            bet.participant.transfer(bet.participantAmount);
        }
        // referee get his tip and his warranty back
        bet.referee.transfer(bet.refereeTip);
        bet.referee.transfer(bet.ownerAmount);
        delete bets[_betId];
    }
    
    /**
     * @dev Returns the money of those involved in the bet, if referee deadline was exceeded
     * @param _betId - id of the bet
     */
    function exceededDeadline(uint256 _betId) external {
        Bet storage bet = bets[_betId];
        require(now > bet.refereeDeadline, "O prazo limite ainda não foi excedido");
        require(msg.sender == bet.owner || msg.sender == bet.participant, "Você não está envolvido na aposta");
        require(bet.participantAccepted == true && bet.refereeAccepted == true, "Essa operação não pode ser realizada. Cancele a aposta");
        // retorna o dinheiro aos envolvidos na aposta, dividindo a garantia do juiz
        bet.owner.transfer(bet.ownerAmount + bet.refereeTip + (bet.ownerAmount/2));
        bet.participant.transfer(bet.participantAmount + (bet.ownerAmount/2));
        delete bets[_betId];
    }
    
    /**
     * @dev Return balance
     * @return balance of this contract
     */
    function checkContractBalance() external view returns (uint256){
        return address(this).balance;
    }
}