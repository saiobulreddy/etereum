pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

contract KYC_Verification{
    
    address admin;
    uint256 totalBanks;
    
    constructor() public {
        admin = msg.sender;
        totalBanks = 0;
    }
    
    struct Customer {
        string userName;   
        string data;  
        bool kycStatus;
        uint256 Downvotes;
        uint256 Upvotes;
        address bank;
    }
    
    struct Bank {
        string name;
        address ethAddress;
        uint256 complaintsReported;
        uint256 KYC_count;
        bool isAllowedToVote;
        string regNumber;
    }

    struct KycRequest{
        string customerName;
        address bankAddress;
        string customerData;
    }
    
    mapping(string => Customer) customers;

    mapping(address => Bank) banks;

    mapping(string => KycRequest) kycRequest;

    // this is an interface to validate that request made by admin or not
    modifier onlyAdmin {
        require(msg.sender == admin, "You are not the admin.");
        _;
    }
    
    // this is an interface to varify the incoming request is from valid bank or not
    modifier isValidBank {
        require(
            banks[msg.sender].ethAddress != address(0) ||
            banks[msg.sender].ethAddress == 0x0000000000000000000000000000000000000000 ||
            bytes(banks[msg.sender].name).length == 0,
            "Not a valid bank account.");
        _;
    }
    
    modifier isBankExist(address _bankAddress) {
        require(
            _bankAddress != address(0) ||
            _bankAddress == 0x0000000000000000000000000000000000000000,
            // banks[_bankAddress].name == null,
            "Bank dosen't exist with provided details."
            );
        _;
    }
    
    // function to add bank by onlyAdmin
    function addBank(string memory _bankName, address _bankAddress, string memory _regNumber) public onlyAdmin {
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNumber;
        banks[_bankAddress].KYC_count = 0;
        banks[_bankAddress].isAllowedToVote = true;
        totalBanks += 1;
    }    
    
    // function to retrive bank details
    function viewBankDetails(address _bankAddress) public view returns (Bank memory) {
        return banks[_bankAddress];
    }    
    
    // function viewBankDetails(address _bankAddress) public view returns (string memory, address, uint256, uint256, bool, string memory) {
    //   return (
        //   banks[_bankAddress].name,
        //   banks[_bankAddress].ethAddress, 
        //   banks[_bankAddress].complaintsReported, 
        //   banks[_bankAddress].KYC_count, 
        //   banks[_bankAddress].isAllowedToVote, 
        //   banks[_bankAddress].regNumber
        //   );
    // }    
    
    // this function is to remove existing bank by admin
    function removeBank(address _bankAddress) public onlyAdmin isBankExist(_bankAddress) {
       delete banks[_bankAddress];
       totalBanks -= 1;
    }    
    
    // to view or listout the complaints on a perticular bank
    function getBankComplaints(address _bankAddress) public isBankExist(_bankAddress) view returns (uint256) {
       return banks[_bankAddress].complaintsReported;
    }    
    
    // to restrict bank's againest casting their votes
    function modifyBankIsAllowedToVote(address _bankAddress, bool isAllowedToVote) public onlyAdmin isBankExist(_bankAddress) {
         banks[_bankAddress].isAllowedToVote = isAllowedToVote;
    }    

    // to report any bank by oter banks
    function reportBank(address _bankAddress, string memory _bankName ) public isValidBank isBankExist(_bankAddress) {
        require(bytes(banks[_bankAddress].name).length != bytes(_bankName).length, "Bank dosen't existed with the provided name.");
        banks[_bankAddress].complaintsReported += 1;
        if(banks[_bankAddress].complaintsReported > totalBanks/3){
            banks[_bankAddress].isAllowedToVote = false;
        }
    } 
    
    // to rise a KYC request for custmor by bank's
    function addRequest(string memory _customerName, string memory _customerData) public isValidBank {
        require(bytes(kycRequest[_customerName].customerName).length == bytes(_customerName).length,"Customer alredy exists with this name.");
        kycRequest[_customerName].customerName = _customerName;
        kycRequest[_customerName].customerData = _customerData;
        kycRequest[_customerName].bankAddress = msg.sender;
        banks[msg.sender].KYC_count += 1;
        this.addCustomer(_customerName, _customerData);
    }
    
    // to cancle the KYC request of a custmor
    function removeRequest(string memory _customerName) public isValidBank {
        require(kycRequest[_customerName].bankAddress != msg.sender,"Not a valid bank to remove the request.");
        require(customers[_customerName].kycStatus == true, "Customer KYC approved, can't be remove.");
        delete kycRequest[_customerName];
    }
    
    // to add new customers into the system
    function addCustomer(string memory _userName, string memory _customerData) public isValidBank isBankExist(msg.sender) {
        // require(keccak256(abi.encodePacked(customers[_userName].userName)) == keccak256(abi.encodePacked(_userName)), "Customer alredy exists with this name.");
        // require(customers[_userName].userName == _userName, "Customer alredy exists with this name.");
        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].Upvotes = 0;
        customers[_userName].Downvotes = 0;
        customers[_userName].kycStatus = false;
        customers[_userName].bank = msg.sender;
    }
    
    // to modify or re-update the custmor data for new KYC request
    function modifyCustomer(string memory _userName, string memory _newcustomerData) public isValidBank {
        require(customers[_userName].bank != msg.sender, "Not an authorisd bank.");
        this.removeRequest(_userName);
        customers[_userName].data = _newcustomerData;
        customers[_userName].Upvotes = 0;
        customers[_userName].Downvotes = 0;
    } 
    
    // to view custmor details 
    function viewCustomer(string memory _userName) public view returns (Customer memory) {
        return customers[_userName];
    }
    
    // function viewCustomer(string memory _userName) public view returns (string memory, string memory, address, bool, uint, uint) {
    //     return (
    //         customers[_userName].userName,
    //         customers[_userName].data,
    //         customers[_userName].bank,
    //         customers[_userName].kycStatus,
    //         customers[_userName].Upvotes,
    //         customers[_userName].Downvotes
    //         );  
    // }
    
    // to vote custmora to approve their KYC docs
    function upvoteCustomer(string memory _customerName) public isValidBank {
        customers[_customerName].Upvotes += 1;
        if(customers[_customerName].Upvotes >= totalBanks/2 && customers[_customerName].Downvotes <= totalBanks/3){
            customers[_customerName].kycStatus = true;
        }
    }    
    
    // to vote custmor to declain their KYC docs
    function downvoteCustomer(string memory _customerName) public isValidBank {
        customers[_customerName].Downvotes += 1;
    }    

    // queries to know about
    // how to compare two strings
    // how to get all the element keys in mapping
    // how to get the count of elements present in mapping
    // how to compare address
}    


