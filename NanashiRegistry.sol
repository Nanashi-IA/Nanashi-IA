// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NanashiRegistry is Ownable {
    // Structure d'une mise à jour (LoRA)
    struct ModelUpdate {
        string version;      // Ex: "1.2.0"
        string ipfsCid;      // Le hash du fichier sur IPFS (ex: Qm...)
        string baseModel;    // Ex: "Llama-3-8B"
        bytes32 checksum;    // Hash SHA256 pour vérifier l'intégrité
        uint256 timestamp;
    }

    // Liste des mises à jour
    ModelUpdate[] public updates;

    // Event pour que le client Python détecte la maj
    event NewUpdatePublished(string version, string ipfsCid, string baseModel);

    constructor() Ownable(msg.sender) {}

    // Fonction pour publier une nouvelle version (Seul toi peux le faire)
    function publishUpdate(
        string memory _version,
        string memory _ipfsCid,
        string memory _baseModel,
        bytes32 _checksum
    ) public onlyOwner {
        updates.push(ModelUpdate({
            version: _version,
            ipfsCid: _ipfsCid,
            baseModel: _baseModel,
            checksum: _checksum,
            timestamp: block.timestamp
        }));

        emit NewUpdatePublished(_version, _ipfsCid, _baseModel);
    }

    // Récupérer la dernière version
    function getLatestUpdate() public view returns (ModelUpdate memory) {
        require(updates.length > 0, "No updates available");
        return updates[updates.length - 1];
    }
}
