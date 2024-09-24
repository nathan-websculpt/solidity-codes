//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

contract GeneralFund {
	struct AddedUsers {
		uint256 userId; //user counter, starting with 1
		string userMsg; //TODO: not needed
		uint16 voteCounter;
	}

	struct Members {
		uint256 memberId; //member counter, starting with 1
		string message; //TODO: not needed
		uint256 timestampAdded;
	}

	//PRODTODO: uint256 public constant frequency = 2592000; //2,592,000 seconds is 4 weeks
	uint256 public constant frequency = 500;
	uint256 public lastTimestamp;
	uint256 public totalAddedSelf = 0;
	uint256 public totalMembers = 0;
	uint256 public totalMonthlyFundsAvailable = 0; //TODO: rename to totalMonthlyFundsAvailable
	uint256 public usersMonthlyLimit = 0;
	uint16 public constant threshold = 2; //TODO: change to 5
	mapping(address => AddedUsers) public userObjs;
	mapping(address => Members) public memberObjs;
	mapping(address => address[]) public vouches; //user => addresses of those who vouched for this user
	mapping(address => uint256) public memberLastWithdrawal; //user => block.timestamp of their last withdrawal

	address[] public originalMembers = [
		0x24eA659E7379fe958A36D829a555c3053C393A40,
		0xd7EDcbd07d8CF0C0a513C6Ec82A1BC9eDa983FA3
	];

	event UserAddedSelf(
		address userAddress,
		string userMsg,
		uint256 userNumber
	);

	event UserVouchedFor(
		bytes userId,
		address userAddress,
		address voucherAddress,
		string reasonVouchingFor //TODO: not needed?
	);

	event Member(
		// address indexed userAddress,
		address memberAddress,
		string memberMsg,
		uint256 memberNumber
	);

	event Month(
		uint256 startTimestamp,
		uint256 endTimestamp,
		uint256 funds,
		uint256 members,
		uint256 fundsPerMember
	);

	event MemberWithdrawal(address memberAddress, uint256 amount);

	event Donation(address donor, uint256 amount);

	modifier notVouchingForSelf(address userToVouchFor, address vouching) {
		require(userToVouchFor != vouching, "You can not vouch for yourself.");
		_;
	}

	modifier notAlreadyVouched(address userToVouchFor, address vouching) {
		require(
			!addressHasVouchedForUser(userToVouchFor, vouching),
			"This address has already vouched for this user."
		);
		_;
	}

	modifier lessThanThreshold(address userToVouchFor) {
		require(
			vouches[userToVouchFor].length < threshold,
			"This user already has enough vouches."
		);
		_;
	}

	modifier notAUser(address potentialUser) {
		require(
			userObjs[potentialUser].userId == 0,
			"Address is already a User."
		);
		_;
	}

	modifier notAMember(address potentialMember) {
		require(
			memberObjs[potentialMember].memberId == 0,
			"Address is already a Member."
		);
		_;
	}

	modifier isAMember(address potentialMember) {
		require(
			memberObjs[potentialMember].memberId != 0,
			"Address is NOT a Member."
		);
		_;
	}

	modifier memberCanWithdraw(address member) {
		require(
			memberLastWithdrawal[member] < lastTimestamp,
			"You have already withdrawn once this month."
		);
		_;
	}

	constructor() {
		for (uint16 i = 0; i < originalMembers.length; i++) {
			makeNewMember(originalMembers[i]);
		}
		lastTimestamp = block.timestamp;
	}

	function addSelf(
		string memory _whyAddedSelf
	) external notAUser(msg.sender) notAMember(msg.sender) {
		totalAddedSelf++;
		AddedUsers storage thisUserObj = userObjs[msg.sender];
		thisUserObj.userId = totalAddedSelf;
		thisUserObj.voteCounter = 0;
		thisUserObj.userMsg = _whyAddedSelf;

		emit UserAddedSelf(msg.sender, _whyAddedSelf, totalAddedSelf);
	}

	function vouchForUser(
		bytes calldata _userId,
		address _userVouchingFor,
		string memory _reasonForVouching
	)
		external
		isAMember(msg.sender)
		notVouchingForSelf(_userVouchingFor, msg.sender)
		notAlreadyVouched(_userVouchingFor, msg.sender)
		lessThanThreshold(_userVouchingFor)
	{
		userObjs[_userVouchingFor].voteCounter++;
		vouches[_userVouchingFor].push(msg.sender);

		emit UserVouchedFor(
			_userId,
			_userVouchingFor,
			msg.sender,
			_reasonForVouching
		);

		//if enough votes - make a member
		if (userObjs[_userVouchingFor].voteCounter >= threshold) {
			makeNewMember(_userVouchingFor);
		}
	}

	function makeNewMember(address _memberAddress) private {
		totalMembers++;
		Members storage thisMemberObj = memberObjs[_memberAddress];
		thisMemberObj.memberId = totalMembers;
		thisMemberObj.message = userObjs[_memberAddress].userMsg;
		thisMemberObj.timestampAdded = block.timestamp;

		emit Member(
			_memberAddress,
			userObjs[_memberAddress].userMsg,
			totalMembers
		);
	}

	function memberWithdrawal()
		external
		isAMember(msg.sender)
		memberCanWithdraw(msg.sender)
	{
		require(address(this).balance > 0, "Sorry! The fund is empty.");
		require(
			address(this).balance >= usersMonthlyLimit,
			"Sorry! The fund does not have enough funds to match the usersMonthlyLimit."
		);
		//The member's Creation-Timestamp must be
		//less-than the current period's Creation-Timestamp
		require(
			memberObjs[msg.sender].timestampAdded <= lastTimestamp,
			"Sorry! You have not been a member long enough to withdraw funds"
		);
		memberLastWithdrawal[msg.sender] = block.timestamp;
		(bool success, ) = payable(msg.sender).call{ value: usersMonthlyLimit }(
			""
		);
		require(success, "Member Withdrawal failed.");

		emit MemberWithdrawal(msg.sender, usersMonthlyLimit);
	}

	function tryFinishMonth() external {
		if (block.timestamp >= lastTimestamp + frequency) finishMonth();
	}

	function returnTimestamp() external view returns (uint256) {
		return block.timestamp;
	}

	function finishMonth() private {
		uint256 prevTimestamp = lastTimestamp;
		lastTimestamp = block.timestamp;
		totalMonthlyFundsAvailable = address(this).balance;
		usersMonthlyLimit = totalMonthlyFundsAvailable / totalMembers;

		emit Month(
			prevTimestamp,
			lastTimestamp,
			totalMonthlyFundsAvailable,
			totalMembers,
			usersMonthlyLimit
		);
	}

	function donate() public payable {
		emit Donation(msg.sender, msg.value);
	}

	function addressHasVouchedForUser(
		address _userToVouchFor,
		address _vouching
	) private view returns (bool) {
		for (uint16 i = 0; i < vouches[_userToVouchFor].length; i++)
			if (vouches[_userToVouchFor][i] == _vouching) return true;

		return false;
	}
	
	receive() external payable {
		donate();
	}
}
