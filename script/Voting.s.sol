pragma solidity ^0.8.13;

contract VotingScript {
    struct Candidate {
        string name;
        uint voteCount;
    }

    Candidate[] public candidates;
    uint public votingDeadline;
    address public ownerAddress;

    mapping(address => bool) public hasVoted;
    address[] public voters;

    event voted(address voter, uint candidateId);

    constructor(uint _votingDuration) {
        votingDeadline = block.timestamp + _votingDuration;
    }

    function addCandidate(string memory _name) public onlyOwner {
        for (uint256 i = 0; i < candidates.length; i++) {
            require(
                keccak256(abi.encodePacked(candidates[i].name)) !=
                    keccak256(abi.encodePacked(_name)),
                "Candidate name already exist"
            );
        }

        candidates.push(Candidate(_name, 0));
    }

    function register() public {
        for (uint256 i = 0; i < voters.length; i++) {
            require(
                keccak256(abi.encodePacked(voters[i])) !=
                    keccak256(abi.encodePacked(msg.sender.address)),
                "You already registered"
            );
        }
        voters.push(msg.sender.address);
    }

    function vote(uint _candidateId) public {
        require(block.timestamp < votingDeadline, "Voting has ended");
        require(!hasVoted[msg.sender], "You have already voted");
        require(_candidateId < candidates.length, "Invalid candidate");

        candidates[_candidateId].voteCount++;
        hasVoted[msg.sender] = true;
        emit voted(msg.sender, _candidateId);
    }

    function getResults() public view returns(Candidate[] memory) {
        require(block.timestamp > votingDeadline, "Voting is still ongoing");

        return candidates;
    }
}
