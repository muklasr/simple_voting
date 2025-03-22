pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;
    uint256 public candidatesCount;
    uint256 public votingDeadline;

    mapping(address => bool) public hasVoted;
    mapping(address => bool) public isRegistered;

    event CandidateAdded(string name);
    event Voted(address indexed voter, uint256 indexed candidateId);
    event Registered(address indexed voter);

    constructor(uint256 _votingDuration) Ownable(msg.sender) {
        votingDeadline = block.timestamp + _votingDuration;
    }

    function addCandidate(string memory _name) public onlyOwner {
        for (uint256 i = 0; i < candidates.length; i++) {
            require(
                keccak256(abi.encodePacked(candidates[i].name)) != keccak256(abi.encodePacked(_name)),
                "Candidate name already exists"
            );
        }

        candidates.push(Candidate(_name, 0));
        candidatesCount++;
        emit CandidateAdded(_name);
    }

    function register() public {
        require(!isRegistered[msg.sender], "You already registered");
        isRegistered[msg.sender] = true;
        emit Registered(msg.sender);
    }

    function vote(uint256 _candidateId) public {
        require(block.timestamp < votingDeadline, "Voting has ended");
        require(isRegistered[msg.sender], "You are not registered to vote");
        require(!hasVoted[msg.sender], "You have already voted");
        require(_candidateId < candidates.length, "Invalid candidate");

        candidates[_candidateId].voteCount++;
        hasVoted[msg.sender] = true;
        emit Voted(msg.sender, _candidateId);
    }

    function getResults() public view returns (Candidate[] memory) {
        require(block.timestamp > votingDeadline, "Voting is still ongoing");
        return candidates;
    }

    function getVoteCount(uint256 _candidateId) public view returns (uint256) {
        require(_candidateId < candidates.length, "Invalid candidate");
        return candidates[_candidateId].voteCount;
    }
}
