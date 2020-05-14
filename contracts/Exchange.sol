pragma solidity ^0.4.21;

import "./ERC20.sol";

contract Exchange {
    
    struct Item {
        string name;
        uint quantity;
        bool hasFeedback;
        bool isClientSatisfied;
    }
    
    enum State { Deployed,
                 Initiated,
                 CancelledByInitiator,
                 ExpiredAcceptance,
                 AcceptedByPartner,
                 RejectedByPartner,
                 Completed }
    event ChangedState(State _state);
    
    Item public initiatorItem;
    Item public partnerItem;
    uint public price;
    State public state;
    
    address public initiator;
    address public partner;
    
    ERC20 public token;
    
    function Exchange(string initiatorItemName, uint initiatorItemQuantity,
                      string partnerItemName, uint partnerItemQuantity, uint _price, 
                      address _initiator, address _partner, ERC20 _token) public {
        initiatorItem = Item(initiatorItemName, initiatorItemQuantity, false, false);
        partnerItem = Item(partnerItemName, partnerItemQuantity, false, false);
        price = _price;
        token = _token;
        initiator = _initiator;
        partner = _partner;
        changeState(State.Deployed);
    }
    
    function contractBalance() public constant returns (uint256) {
        return token.balanceOf(this);
    }
    
    modifier onlyInitiator() {
        require(initiator == msg.sender);
        _;
    }

    modifier onlyInitiatorOrToken() {
        require(initiator == msg.sender || token == msg.sender);
        _;
    }
    
    modifier onlyPartnerOrToken() {
        require(partner == msg.sender || token == msg.sender);
        _;
    }
    
    modifier onlyPartner() {
        require(partner == msg.sender);
        _;
    }
    
    modifier inState(State _state) {
        require(state == _state);
        _;
    }
    
    function initiate() public onlyInitiatorOrToken inState(State.Deployed) {
        require(token.transferFrom(initiator, address(this), price));
        changeState(State.Initiated);
    }
    
    function cancel() public onlyInitiator inState(State.Initiated) {
        changeState(State.CancelledByInitiator);
        require(token.approve(initiator, price));
        require(token.transfer(initiator, price));
    }
    
    function accept() public onlyPartnerOrToken inState(State.Initiated) {
        require(token.transferFrom(partner, address(this), price));
        changeState(State.AcceptedByPartner);
    }
    
    function reject() public onlyPartner inState(State.Initiated) {
        changeState(State.RejectedByPartner);
        require(token.approve(initiator, price));
        require(token.transfer(initiator, price));
    }
    
    function givePartnerItemFeedback(bool _isSatisfied) public onlyInitiator inState(State.AcceptedByPartner) {
        partnerItem.isClientSatisfied = _isSatisfied;
        partnerItem.hasFeedback = true;
        checkForCompletion();
    }
    
    function giveInitiatorItemFeedback(bool _isSatisfied) public onlyPartner inState(State.AcceptedByPartner) {
        initiatorItem.isClientSatisfied = _isSatisfied;
        initiatorItem.hasFeedback = true;
        checkForCompletion();
    }
    
    function checkForCompletion() private inState(State.AcceptedByPartner) {
        if (initiatorItem.hasFeedback && partnerItem.hasFeedback) {
            
            if (initiatorItem.isClientSatisfied && partnerItem.isClientSatisfied) {
                require(token.approve(initiator, price));
                require(token.approve(partner, price));
                require(token.transfer(initiator, price));
                require(token.transfer(partner, price));
            }
            changeState(State.Completed);
        }
    }
    
    function changeState(State _state) private {
        state = _state;
        emit ChangedState(state);
    }
}
