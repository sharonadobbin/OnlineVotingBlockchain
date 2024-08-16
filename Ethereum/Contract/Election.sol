// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ElectionFact is ReentrancyGuard {
    
    struct ElectionDet {
        address deployedAddress;
        string el_n;
        string el_d;
    }
    
    mapping(string => ElectionDet) private companyEmail;
    
    event ElectionCreated(address indexed electionAddress, string email, string electionName, string electionDescription);

    function createElection(string memory email, string memory election_name, string memory election_description) public nonReentrant {
        Election newElection = new Election(msg.sender, election_name, election_description);
        
        companyEmail[email].deployedAddress = address(newElection);
        companyEmail[email].el_n = election_name;
        companyEmail[email].el_d = election_description;

        emit ElectionCreated(address(newElection), email, election_name, election_description);
    }
    
    function getDeployedElection(string memory email) public view returns (address, string memory, string memory) {
        address val = companyEmail[email].deployedAddress;
        if (val == address(0)) {
            return (address(0), "", "Create an election.");
        } else {
            ElectionDet memory det = companyEmail[email];
            return (det.deployedAddress, det.el_n, det.el_d);
        }
    }
}

contract Election is ReentrancyGuard {

    address public immutable election_authority;
    string public election_name;
    string public election_description;
    bool public status;

    struct Candidate {
        string candidate_name;
        string candidate_description;
        string imgHash;
        uint256 voteCount;
        string email;
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(string => Voter) private voters;

    struct Voter {
        uint256 candidate_id_voted;
        bool voted;
    }

    uint256 public numCandidates;
    uint256 public numVoters;

    event CandidateAdded(uint256 candidateID, string candidateName, string candidateDescription, string imgHash, string email);
    event Voted(uint256 candidateID, string voterEmail);

    constructor(address authority, string memory name, string memory description) {
        election_authority = authority;
        election_name = name;
        election_description = description;
        status = true;
    }

    modifier onlyOwner() {
        require(msg.sender == election_authority, "Error: Access Denied.");
        _;
    }

    function addCandidate(string memory candidate_name, string memory candidate_description, string memory imgHash, string memory email) public onlyOwner nonReentrant {
        uint256 candidateID = numCandidates++;
        candidates[candidateID] = Candidate(candidate_name, candidate_description, imgHash, 0, email);
        emit CandidateAdded(candidateID, candidate_name, candidate_description, imgHash, email);
    }

    function vote(uint256 candidateID, string memory e) public nonReentrant {
        require(!voters[e].voted, "Error: You cannot double vote");
        require(candidateID < numCandidates, "Error: Invalid candidate ID");

        voters[e] = Voter(candidateID, true);
        numVoters++;
        candidates[candidateID].voteCount++;

        emit Voted(candidateID, e);
    }

    function getNumOfCandidates() public view returns (uint256) {
        return numCandidates;
    }

    function getNumOfVoters() public view returns (uint256) {
        return numVoters;
    }

    function getCandidate(uint256 candidateID) public view returns (string memory, string memory, string memory, uint256, string memory) {
        require(candidateID < numCandidates, "Error: Invalid candidate ID");
        Candidate memory candidate = candidates[candidateID];
        return (candidate.candidate_name, candidate.candidate_description, candidate.imgHash, candidate.voteCount, candidate.email);
    } 

    function winnerCandidate() public view onlyOwner nonReentrant returns (uint256) {
        uint256 largestVotes = candidates[0].voteCount;
        uint256 candidateID = 0;

        for (uint256 i = 1; i < numCandidates; i++) {
            if (candidates[i].voteCount > largestVotes) {
                largestVotes = candidates[i].voteCount;
                candidateID = i;
            }
        }
        return candidateID;
    }
    
    function getElectionDetails() public view returns (string memory, string memory) {
        return (election_name, election_description);
    }
}
