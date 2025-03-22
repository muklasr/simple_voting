// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Voting} from "../src/Voting.sol";

contract VotingTest is Test {
    Voting public voting;
    address user = address(0x123);

    function setUp() public {
        voting = new Voting(52000); // 52000 seconds voting duration
    }

    function test_AddCandidate_Success() public {
        _addCandidate("mulyono", true);
    }

    function test_AddCandidate_CandidateExist() public {
        _addCandidate("mulyono", true);

        vm.expectRevert("Candidate name already exists");
        voting.addCandidate("mulyono");
    }

    function test_AddCandidate_MultipleCandidatesSuccess() public {
        _addCandidate("mulyono", true);
        _addCandidate("mulyani", true);
    }

    function test_Register_Success() public {
        _register(user, true);
    }

    function test_Register_AlreadyRegistered() public {
        _register(user, true);

        vm.expectRevert("You already registered");
        _register(user, false);
    }

    function test_Vote_Success() public {
        _setupVoting();

        (, uint256 voteCount) = voting.candidates(0);
        assertEq(voteCount, 1);
        assertTrue(voting.hasVoted(user));
    }

    function test_Vote_NotRegistered() public {
        _addCandidate("mulyono", true);

        vm.expectRevert("You are not registered to vote");
        _vote(user, 0);
    }

    function test_Vote_AlreadyVoted() public {
        _setupVoting();

        vm.expectRevert("You have already voted");
        _vote(user, 0);
    }

    function test_Vote_InvalidCandidate() public {
        _addCandidate("mulyono", false);
        _register(user, false);

        vm.expectRevert("Invalid candidate");
        _vote(user, 1); // ID 1 ga ada
    }

    function test_Vote_VotingEnded() public {
        _addCandidate("mulyono", false);
        _register(user, false);

        vm.warp(block.timestamp + 52001);
        vm.expectRevert("Voting has ended");
        _vote(user, 0);
    }

    function test_GetResults_Success() public {
        _setupVoting();

        // Move time forward to end voting
        vm.warp(block.timestamp + 52002);
        Voting.Candidate[] memory result = voting.getResults();

        assertEq(result.length, 1, "Candidate count mismatch");
        assertEq(result[0].name, "mulyono", "Candidate name mismatch");
        assertEq(result[0].voteCount, 1, "Vote count mismatch");
    }

    function test_GetResults_VotingOngoing() public {
        _setupVoting();

        // Try to get results before voting ends
        vm.warp(block.timestamp + 1);
        vm.expectRevert("Voting is still ongoing");
        voting.getResults();
    }

    function test_GetVoteCount_Success() public {
        _setupVoting();
        assertEq(voting.getVoteCount(0), 1, "Candidate's vote count mismatch");
    }

    function test_GetVoteCount_InvalidCandidate() public {
        _setupVoting();

        vm.expectRevert("Invalid candidate");
        voting.getVoteCount(1);
    }

    /// @dev Helper function to add a candidate
    function _addCandidate(string memory candidateName, bool expectEmit) internal {
        if (expectEmit) {
            _expectEmitCandidateAdded(candidateName);
        }
        voting.addCandidate(candidateName);
        _assertCandidate(candidatesCount() - 1, candidateName, 0);
    }

    /// @dev Helper function to register a voter
    function _register(address voter, bool expectEmit) internal {
        if (expectEmit) {
            _expectEmitRegistered(voter);
        }
        vm.prank(voter);
        voting.register();
        assertTrue(voting.isRegistered(voter));
    }

    /// @dev Helper function to cast vote
    function _vote(address voter, uint256 candidateId) internal {
        vm.prank(voter);
        voting.vote(candidateId);
    }

    /// @dev Helper function to assert candidate correctness
    function _assertCandidate(uint256 index, string memory expectedName, uint256 expectedVoteCount) internal view {
        (string memory name, uint256 voteCount) = voting.candidates(index);
        assertEq(name, expectedName);
        assertEq(voteCount, expectedVoteCount);
    }

    /// @dev Returns the current number of candidates
    function candidatesCount() internal view returns (uint256) {
        return voting.candidatesCount();
    }

    /// @dev Helper function to expect CandidateAdded event
    function _expectEmitCandidateAdded(string memory candidateName) internal {
        vm.expectEmit(true, true, true, true);
        emit Voting.CandidateAdded(candidateName);
    }

    /// @dev Helper function to expect Registered event
    function _expectEmitRegistered(address voter) internal {
        vm.expectEmit(true, true, true, true);
        emit Voting.Registered(voter);
    }

    /// @dev Helper function to setup a candidate, register, and vote
    function _setupVoting() internal {
        _addCandidate("mulyono", false);
        _register(user, false);
        _vote(user, 0);
    }
}
