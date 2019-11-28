/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
and download one Abstract contract for the full ERC 20 Token standard and keep it in same folder in Remix IDE from https://github.com/ConsenSys/Tokens/blob/master/contracts/eip20/EIP20Interface.sol
.*/


pragma solidity ^0.5.1; 

import "./EIP20Interface.sol";


contract JMICoinContract is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /* Keep track of ETH funds raised */
    uint amountRaised;
    uint amount2;
    
    /* Address of the wallet holding the token funds when they are first created */
    address payable tokenFundsAddress;
    
    /* Approved address of the account that will receive the raised Ether funds */
    address payable beneficiary;

    /* This generates a public event on the blockchain that will notify listening clients */
    event TransferGB(address indexed from, address indexed to, uint value);
    event FundsRaised(address indexed from, uint fundsReceivedInEther, uint tokensIssued);
    event ETHFundsWithdrawn(address indexed recipient, uint fundsWithdrawnInEther);
    
    /* Price of a JMICoin, in 'wei' denomination */
    uint constant private TOKEN_PRICE_IN_WEI = 0.01 * 1 ether;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */

    string public name;                   //fancy name: eg JMICoin
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg JMIC

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;  
        // store a reference to this contract creator's address, 
        // so we can debit tokens from this address each time we distribute tokens to
        // a crowdsale participant
        tokenFundsAddress = msg.sender;
        
        // the beneficiary for the crowd sale (the one who will receive the raised ETH)
        // should be the same as the account holding the tokens to be given away
        beneficiary = tokenFundsAddress;// Set the symbol for display purposes
    }

    modifier onlyOwner() {
        require(msg.sender == beneficiary);
        _;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function buyTokensWithEther() public payable {
        // calculate # of tokens to give based on 
        // amount of Ether received and the token's fixed price
        uint numTokens = msg.value / TOKEN_PRICE_IN_WEI;
        
        // take funds out of our token holdings and to prevent from Underflow
        require(balances[tokenFundsAddress] >= numTokens);
        balances[tokenFundsAddress] -= numTokens;
        
        // deposit those tokens into the buyer's account and to prevent from Overflow
        require(balances[msg.sender] + numTokens >= balances[msg.sender]);
        balances[msg.sender] += numTokens;
        
        // update our tracker of total ETH raised
        // during this crowdsale
        amountRaised += msg.value;
        amount2 = amountRaised;
        amount2 = amount2 / 1000000000000000000;

        emit FundsRaised(msg.sender, msg.value/1000000000000000000, numTokens);
    }
    
    function getAmountRaised() public view returns (uint) {
        return amount2;
    }
    
    function withdrawRaisedFunds() public {
        
        // verify that the account requesting the funds
        // is the approved beneficiary
        if (msg.sender != beneficiary)
            return;
        
        // transfer ETH from this contract's balance
        // to the rightful recipient
        beneficiary.transfer(amountRaised);
        
        emit ETHFundsWithdrawn(beneficiary, amount2);
        
    }
    
     /* Function to recover the funds on the contract */
    function kill() public onlyOwner() {
        selfdestruct(beneficiary);
    }
}
