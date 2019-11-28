pragma solidity ^0.5.1;

contract SimpleStorage {
    uint storedNum;
    
    function set(uint x) public {
        storedNum=x;
    }
    
    function get() public view returns(uint){
        return storedNum;
    }
}
