//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//TODO: REMOVE
import "hardhat/console.sol";

/**
 * WARNING: CONTRACT IS CURRENTLY FOR PROOF-OF-CONCEPT
 * WARNING: CONTRACT HAS NOT BEEN AUDITED
 * Dev/Testing: I want to see how well this works and do some cost-analysis.
 *
 *
 * At the time of writing, I can not confirm that the goal of this contract will be achieved;
 * THEREFORE, I can not assert that this will properly represent The Gospel of John (KJV) [neither in-part, nor in-full];
 * This will hopefully serve the purpose of saying, "Look, it is possible."
 * But, if you wanted to read The Gospel of John (KJV) yourself, this contract (or, this iteration of this contract) is not the right source.
 * One area where this text will be lacking is that it will not contain any of the original italics.
 *
 * The intention of this smart contract is to store/confirm (verse-by-verse) The Gospel of John (KJV) on Optimism,
 * and (if all goes well) this could evolve to become a template for other books/documents.
 *
 * Ideally, I believe that this would be better with a council-of-members voting on the validity of a section-of-text BEFORE it is stored.
 * This is more than protecting books against censorship. The blockchain could also allow us to timestamp the moment a group of
 * people agreed upon the contents of a book/written-work/document.
 * I do intend to try this with items like the Declaration of Independence, as well.
 *
 * WARNING: CONTRACT IS CURRENTLY FOR PROOF-OF-CONCEPT
 * WARNING: CONTRACT HAS NOT BEEN AUDITED
 * If you wish to donate, please do not use this contract's functionality.
 * Instead, simply send funds to: 0x1e7aAbB9D0C701208E875131d0A1cFcDAba79350
 * My most-sincere feeling of gratitude goes to anyone wanting to help out.
 *
 * @author
 * nathan-websculpt
 * https://github.com/nathan-websculpt
 * 0x1e7aAbB9D0C701208E875131d0A1cFcDAba79350
 *
 * Please see my repo: 'crowd-fund-v4' to see how a council-of-members can vote on text before it is processed.
 */

contract John is Ownable, ReentrancyGuard {
	/**
		Contract will have a good/bad state that members must vote on -- they will do this at the end, 
			asserting whether or not the effort was a success
	 */

	/**
		Either: Verses will have two copies (draft and fully-confirmed);
		    OR: Verses will have a bool that changes when it is fully-confirmed;
	 */

	struct VerseStr {
		uint256 verseId;
		uint256 verseNumber;
		uint256 chapterNumber;
		string verseContent;
		bool confirmed;
	}

	mapping(uint256 => VerseStr) public verses;
	mapping(address => uint256[]) public confirmations;
	mapping(uint256 => address[]) public verseConfirmations;
	address[] public council;
	address[] public votedToExitEditMode;
	uint256 public numberOfVerses = 0;
	bool public contractInEditMode = true;

	//TODO: indexed parameters
	event Verse(
		address signer,
		uint256 verseId,
		uint256 verseNumber,
		uint256 chapterNumber,
		string verseContent
	);

	event Confirmation(address confirmedBy, bytes verseId);

	event FinalConfirmation(address confirmedBy, bytes verseId);

	event Donation(address donor, uint256 amount);

	modifier isContractInEditMode() {
		require(
			contractInEditMode,
			"This Contract has been voted as complete; therefore, no more verses can be added."
		);
		_;
	}

	modifier memberOfCouncil(address addr) {
		bool canContinue = false;
		for (uint256 i = 0; i < council.length; i++) {
			if (council[i] == addr) {
				canContinue = true;
				break;
			}
		}
		require(
			canContinue,
			"Only members of the Council have access to this functionality."
		);
		_;
	}

	modifier userHasNotConfirmed(address addr, uint256 verseId) {
		bool canContinue = true;
		for (uint256 i = 0; i < confirmations[addr].length; i++) {
			if (confirmations[addr][i] == verseId) {
				canContinue = false;
				break;
			}
		}
		require(canContinue, "This address has already confirmed this verse.");
		_;
	}

	modifier verseNotConfirmed(uint256 verseId) {
		require(
			!verses[verseId].confirmed,
			"This verse already has enough confirmations"
		); //this is probably redundant, since only members can confirm
		_;
	}

	modifier hasNotVotedToExitEditMode(address addr) {
		bool canContinue = true;
		for (uint256 i = 0; i < votedToExitEditMode.length; i++) {
			if (votedToExitEditMode[i] == addr) {
				canContinue = false;
				break;
			}
		}
		require(
			canContinue,
			"This address has already voted to exit Edit Mode"
		);
		_;
	}

	constructor(address _contractOwner, address[] memory _council) {
		_transferOwnership(_contractOwner);
		council = _council;
	}

	receive() external payable {
		donate();
	}

	function addBatchVerses(
		uint256[] memory _verseNumber,
		uint256[] memory _chapterNumber,
		string[] memory _verseContent
	) external memberOfCouncil(msg.sender) isContractInEditMode {
		uint256 length = _verseNumber.length;
		require(
			length == _chapterNumber.length,
			"Invalid array lengths - lengths did not match."
		);
		require(
			length == _verseContent.length,
			"Invalid array lengths - lengths did not match."
		);
		//make sure a verse has been added before checking for skipped verses/chapters
		if (verses[1].verseNumber != 0) {
			require(
				preventSkippingVerse(_verseNumber[0], _chapterNumber[0]),
				"The contract is preventing you from skipping a verse."
			);
			require(
				preventSkippingChapter(_chapterNumber[0]),
				"The contract is preventing you from skipping a chapter."
			);
			require(
				enforceFirstVerseOfNewChapter(
					_verseNumber[0],
					_chapterNumber[0]
				),
				"The contract is preventing you from starting a new chapter with a verse that is not 1."
			);
		} else {
			//this is a first-verse scenario
			require(enforceFirstVerse(_verseNumber[0], _chapterNumber[0]), "The contract is preventing you from starting with a verse that is not 1:1");
		}
		for (uint256 i = 0; i < length; i++) {
			_storeVerse(_verseNumber[i], _chapterNumber[i], _verseContent[i]);
		}
	}

	//to prevent skipping verses
	//prevents the situation of storing 1:1 and then storing 1:3
	function preventSkippingVerse(
		uint256 _verseNumber,
		uint256 _chapterNumber
	) private view returns (bool) {
		bool canContinue = true;
		VerseStr storage lastVerseAdded = verses[numberOfVerses];

		console.log(
			"\t\tHARDHAT CONSOLE: lastVerseAdded chap num: %s ... and this chap num: %s",
			lastVerseAdded.chapterNumber,
			_chapterNumber
		);

		console.log(
			"\t\tHARDHAT CONSOLE: lastVerseAdded verse num + 1: %s ... and this verse num: %s",
			lastVerseAdded.verseNumber + 1,
			_verseNumber
		);

		if (lastVerseAdded.chapterNumber == _chapterNumber) {
			if (_verseNumber != lastVerseAdded.verseNumber + 1) {
				canContinue = false; //in this situation, they are skipping a verse;
				//likely no real way to know if they are skipping verses IF the chapter number changes
			}
		}
		console.log(
			"\t\tHARDHAT CONSOLE: preventSkippingVerse() canContinue: %s",
			canContinue
		);
		return canContinue;
	}

	//to prevent skipping chapters
	//prevents the situation of storing 1:1 and then storing 2:2
	function preventSkippingChapter(
		uint256 _chapterNumber
	) private view returns (bool) {
		bool canContinue = true;
		VerseStr storage lastVerseAdded = verses[numberOfVerses];
		if (
			_chapterNumber != lastVerseAdded.chapterNumber &&
			_chapterNumber != lastVerseAdded.chapterNumber + 1
		) {
			canContinue = false; //in this situation, they are skipping a chapter;
		}
		console.log(
			"\t\tHARDHAT CONSOLE: preventSkippingChapter canContinue: %s",
			canContinue
		);
		return canContinue;
	}
	//TODO: ^^^ with the use of metadata (about the book, like how many verses each chapter has) that gets voted on, this could be tightened down even more

	function enforceFirstVerseOfNewChapter(
		uint256 _verseNumber,
		uint256 _chapterNumber
	) private view returns (bool) {
		bool canContinue = true;
		VerseStr storage lastVerseAdded = verses[numberOfVerses];
		if (
			_chapterNumber != lastVerseAdded.chapterNumber && _verseNumber != 1
		) {
			canContinue = false;
		}
		return canContinue;
	}

	function enforceFirstVerse(
		uint256 _verseNumber,
		uint256 _chapterNumber
	) private pure returns (bool) {
		bool canContinue = true;
		if(_chapterNumber != 1 || _verseNumber != 1) {
			canContinue = false;
		}
		return canContinue;
	}

	function confirmVerse(
		bytes memory _verseId,
		uint256 _numericalId
	)
		external
		isContractInEditMode
		memberOfCouncil(msg.sender)
		userHasNotConfirmed(msg.sender, _numericalId)
		verseNotConfirmed(_numericalId)
	{
		confirmations[msg.sender].push(_numericalId);
		verseConfirmations[_numericalId].push(msg.sender);
		emit Confirmation(msg.sender, _verseId);
		tryFullyConfirmVerse(_verseId, _numericalId);
	}

	function tryFullyConfirmVerse(
		bytes memory _verseId,
		uint256 _numericalId
	) private {
		if (verseConfirmations[_numericalId].length == council.length) {
			verses[_numericalId].confirmed = true;
			emit FinalConfirmation(msg.sender, _verseId);
		}
	}

	function voteToExitEditMode()
		external
		isContractInEditMode
		memberOfCouncil(msg.sender)
		hasNotVotedToExitEditMode(msg.sender)
	{
		votedToExitEditMode.push(msg.sender);
		if (votedToExitEditMode.length == council.length) {
			tryExitEditMode();
		}
	}

	function tryExitEditMode() public isContractInEditMode {
		bool canContinue = true;
		for (uint256 i = 0; i < council.length; i++) {
			if (!councilMemberHasVotedToExitEditMode(council[i])) {
				canContinue = false;
				break;
			}
		}
		require(
			canContinue,
			"Can not exit Edit Mode, because there either aren't enough votes or there is a problem with one of the votes."
		);
		contractInEditMode = false;
	}

	function councilMemberHasVotedToExitEditMode(
		address councilMember
	) private view returns (bool) {
		bool canContinue = false;
		for (uint256 i = 0; i < votedToExitEditMode.length; i++) {
			if (votedToExitEditMode[i] == councilMember) {
				canContinue = true;
				break;
			}
		}
		return canContinue;
	}

	function withdraw() external onlyOwner nonReentrant {
		address contractOwner = owner();
		require(address(this).balance > 0, "There is nothing to withdraw.");
		(bool success, ) = payable(contractOwner).call{
			value: address(this).balance
		}("");
		require(success, "Failed to send Ether");
	}

	function donate() public payable {
		emit Donation(msg.sender, msg.value);
	}

	function _storeVerse(
		uint256 _verseNumber,
		uint256 _chapterNumber,
		string memory _verseContent
	) private {
		numberOfVerses++;
		VerseStr storage thisVerse = verses[numberOfVerses];
		thisVerse.verseId = numberOfVerses;
		thisVerse.verseNumber = _verseNumber;
		thisVerse.chapterNumber = _chapterNumber;
		thisVerse.verseContent = _verseContent;
		thisVerse.confirmed = false;

		emit Verse(
			msg.sender,
			numberOfVerses,
			_verseNumber,
			_chapterNumber,
			_verseContent
		);
	}

	function getLastVerseAdded() external view returns (VerseStr memory) {
		return verses[numberOfVerses];
	}

	function getVerseByNumber(uint256 _numericalId) external view returns(VerseStr memory) {
		return verses[_numericalId];
	}
}
