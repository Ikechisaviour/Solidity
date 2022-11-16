// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.8.0;

// pragma experimental ABIEncoderV2;

contract purewallet {

    struct accountProperties{ //Temporary data for mobile application
        uint256[] money;
        uint totalBalance;
        bytes32 [] hashMoneyList;
        uint256 used;       
    }

    struct accountPropertiesPam{ //Permanent data for withdrawal purpose
        uint256[] money;
        uint256 totalBalance;
        bytes32 [] hashMoneyList;
        uint256 used;
    }

    bytes32[] public allhash3256; //Hash3s for public verification
    bytes32[] private allhash1;

    address payable owner = msg.sender;
    uint256 private time = block.timestamp;

    mapping (address => accountProperties) public depositors;
    mapping (address => accountPropertiesPam) public depositorsPam;


    string zza;
    string zzd;

    bool internal locked = false;
   
    function storeMoney (uint256 nom) payable public{ //Deposit function
                
        accountProperties storage depositor = depositors[msg.sender];
        bytes32 aaa = keccak256(abi.encodePacked(msg.value, block.timestamp-time, nom));
        zza = toHex(aaa);
        depositor.hashMoneyList.push(aaa);
        depositor.money.push(msg.value);
        allhash1.push(aaa);
        bytes32 aad = sha256(abi.encodePacked(zza));
        zzd = toHex(aad);
        bytes32 aae = sha256(abi.encodePacked(zzd));
        allhash3256.push(aae); 

        accountPropertiesPam storage depositorPam = depositorsPam[msg.sender];
        depositorPam.money.push(msg.value);
        depositorPam.totalBalance += msg.value;
        depositorPam.hashMoneyList.push(aaa);         
    }

    
    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
    result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
          (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
          (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
          (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
          (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
          (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
           uint256 (result) +
           (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
           0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 39);
    }

    function toHex (bytes32 data) public pure returns (string memory) {
        return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
    }
    
    function withdrawNoAddress (address _address, bytes32 _hashMoney) payable public { //Withdrawal function

        require(!locked); //Reentrancy attack security
        locked = true;        
        address payable _to = payable(msg.sender);
        
        findUserPam(_address, _hashMoney);       
        
        if (depositorsPam[_address].hashMoneyList[depositorsPam[_address].used] == _hashMoney){
            uint a = depositorsPam[_address].money[depositorsPam[_address].used];
            require (depositorsPam[_address].totalBalance >= a);
            depositorsPam[_address].hashMoneyList[depositorsPam[_address].used] = depositorsPam[_address].hashMoneyList[depositorsPam[_address].hashMoneyList.length - 1];
            depositorsPam[_address].hashMoneyList.pop();

            depositorsPam[_address].money[depositorsPam[_address].used] = depositorsPam[_address].money[depositorsPam[_address].money.length - 1];
            depositorsPam[_address].money.pop(); 
            
            require(depositorsPam[_address].totalBalance >= a);
            depositorsPam[_address].totalBalance -= a;
            _to.transfer(a); 
            
        } 

        for(uint i=0;i<allhash1.length;i++){ 
            if(allhash1[i] == _hashMoney){ 
                allhash1[i] = allhash1[allhash1.length-1]; 
                allhash1.pop();
                allhash3256[i] = allhash3256[allhash3256.length-1]; 
                allhash3256.pop();
                
            } 
        }
        locked = false; 
    }

    function sendMoney(address payable _address) payable public { //Send money directly when online
        require (_address != msg.sender);
        _address.transfer(msg.value); 
    }

   function viewAccountBalance () public view returns(uint){ //Individual account balance
        return depositors[msg.sender].totalBalance;
    }

    function findUser(address _address, bytes32 _hashMoney) private{
        uint i; 
        for(i=0;i<depositors[_address].hashMoneyList.length;i++){ 
            if(depositors[_address].hashMoneyList[i] == _hashMoney){ 
                depositors[_address].used = i; 
            } 
        }  
    }  

    function findUserPam(address _address, bytes32 _hashMoney) private{
        uint i; 
        for(i=0;i<depositorsPam[_address].hashMoneyList.length;i++){ 
            if(depositorsPam[_address].hashMoneyList[i] == _hashMoney){ 
                depositorsPam[_address].used = i; 
            } 
        }  
    } 

    function remove() public { //Remove Temporay data
        depositors[msg.sender].hashMoneyList.pop();
        depositors[msg.sender].money.pop();
    }

    function viewHashes ()public view returns(bytes32 [] memory){
        return depositors[msg.sender].hashMoneyList;
    }

    function vPamHash ()public view returns(bytes32 [] memory){
        return depositorsPam[msg.sender].hashMoneyList;
    }

    function vPamMoney ()public view returns(uint256 [] memory){
        return depositorsPam[msg.sender].money;
    }

    function viewAllHash3256 ()public view returns(bytes32 [] memory){
        return allhash3256;
    }

    function countHashes ()public view returns(uint){
        return allhash1.length;
    }

    function viewContractBalance()public view returns(uint){
        return address(this).balance;
    }

    function viewMoneyValue ()public view returns(uint256 [] memory){
        return depositors[msg.sender].money;
    } 
   
    function withdrawBalance () public { 
        require(!locked); //Reentrancy attack security
        locked = true; 
        uint empty = depositorsPam[msg.sender].totalBalance; 
        depositorsPam[msg.sender].totalBalance = 0;          
        msg.sender.transfer(empty);
        for(uint i=0;i<depositorsPam[msg.sender].hashMoneyList.length;i++){ 
            for(uint j = 0; j<allhash1.length; j++){

                if(allhash1[j] == depositorsPam[msg.sender].hashMoneyList[i]){ 
                    allhash1[j] = allhash1[allhash1.length-1]; 
                    allhash1.pop();
                    allhash3256[j] = allhash3256[allhash3256.length-1]; 
                    allhash3256.pop();
                    
                } 
            }
        }
        delete depositorsPam[msg.sender].hashMoneyList;
        delete depositorsPam[msg.sender].money;
        locked = false; 
    }

    receive() external payable{}

}
