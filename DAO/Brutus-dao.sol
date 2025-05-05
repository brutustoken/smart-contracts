// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BrutusDAO {
    address public owner;
    uint public proposalCount = 0;
    uint public quorum = 1; // mínimo de votos requeridos

    struct Proposal {
        uint id;
        string description;
        uint deadline;
        uint votesYes;
        uint votesNo;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint => Proposal) public proposals;
    mapping(address => bool) public members;

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "No eres miembro");
        _;
    }

    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
    }

    function addMember(address _member) external onlyOwner {
        members[_member] = true;
    }

    function createProposal(string calldata _desc) external onlyMember {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.description = _desc;
        p.deadline = block.timestamp + 3 days;
    }

    function vote(uint _proposalId, bool _support) external onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp < p.deadline, "Votacion cerrada");
        require(!p.voted[msg.sender], "Ya votaste");

        if (_support) {
            p.votesYes++;
        } else {
            p.votesNo++;
        }
        p.voted[msg.sender] = true;
    }

    function executeProposal(uint _proposalId) external onlyMember {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.deadline, "Aun no termina");
        require(!p.executed, "Ya ejecutado");
        require(p.votesYes + p.votesNo >= quorum, "No hay quorum");

        if (p.votesYes > p.votesNo) {
            // Aquí iría la acción (como transferir fondos, etc.)
            // Ejemplo: ejecutar función externa o cambiar estado
        }

        p.executed = true;
    }
}
