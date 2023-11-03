// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract EHR {
    // Patient struct
    struct Patient {
        string name;
        uint256 age;
        string gender;
        string diagnosis;
        string prescription;
        bool isAuthorized;
        bool exists;
    }

    // Doctor struct
    struct Doctor {
        string name;
        uint256 age;
        string gender;
        string specialty;
        bool exists;
    }

    // Mapping of patient addresses to their record
    mapping(address => Patient) private patients;

    // Mapping of doctor addresses to their record
    mapping(address => Doctor) private doctors;

    // Mapping of patient addresses to their authorized doctors
    mapping(address => mapping(address => bool)) private patientDoctor;

    // Event to log when a patient record is created or updated
    event PatientRecord(address indexed patientAddress, string name, uint256 age, string gender, string diagnosis, string prescription);

    // Event to log when a doctor record is created or updated
    event DoctorRecord(address indexed doctorAddress, string name, uint256 age, string gender, string specialty);

    // Event to log when a patient authorizes a doctor to access their record
    event AuthorizeDoctor(address indexed patientAddress, address indexed doctorAddress);

    // Event to log when a patient revokes a doctor's access to their record
    event RevokeAccess(address indexed patientAddress, address indexed doctorAddress);

    // Event to log when a patient record is deleted
    event RemoveRecord(address indexed patientAddress);

    // Function to create or update a patient record
    function createOrUpdateRecord(string memory _name, uint256 _age, string memory _gender, string memory _diagnosis, string memory _prescription) public {
        // Create or update the patient record
        patients[msg.sender].name = _name;
        patients[msg.sender].age = _age;
        patients[msg.sender].gender = _gender;
        patients[msg.sender].diagnosis = _diagnosis;
        patients[msg.sender].prescription = _prescription;
        patients[msg.sender].exists = true;

        // Emit the patient record event
        emit PatientRecord(msg.sender, _name, _age, _gender, _diagnosis, _prescription);
    }

    // Function to get a patient record
    function getRecord(address _patientAddress) public view returns (string memory, uint256, string memory, string memory, string memory, bool) {
        // Check if the patient record exists
        require(patients[_patientAddress].exists == true, "Patient record does not exist");

        // Check if the caller is authorized to access the patient record
        require(patients[_patientAddress].isAuthorized == true || msg.sender == _patientAddress, "Caller is not authorized to access patient record");

        // Return the patient record
        return (
            patients[_patientAddress].name,
            patients[_patientAddress].age,
            patients[_patientAddress].gender,
            patients[_patientAddress].diagnosis,
            patients[_patientAddress].prescription,
            patients[_patientAddress].isAuthorized
        );
    }

    // Function to update a patient record
    function updateRecord(string memory _name, uint256 _age, string memory _gender, string memory _diagnosis, string memory _prescription) public {
        // Check if the patient record exists
        require(patients[msg.sender].exists == true, "Patient record does not exist");

        // Update the patient record
        patients[msg.sender].name = _name;
        patients[msg.sender].age = _age;
        patients[msg.sender].gender = _gender;
        patients[msg.sender].diagnosis = _diagnosis;
        patients[msg.sender].prescription = _prescription;

        // Emit the patient record event
        emit PatientRecord(msg.sender, _name, _age, _gender, _diagnosis, _prescription);
    }

    // Function to delete a patient record
    function deleteRecord() public {
        // Check if the patient record exists
        require(patients[msg.sender].exists == true, "Patient record does not exist");

        // Delete the patient record
        delete patients[msg.sender];

        // Emit the remove record event
        emit RemoveRecord(msg.sender);
    }

    // Function to create or update a doctor record
    function createOrUpdateDoctor(string memory _name, uint256 _age, string memory _gender, string memory _specialty) public {
        // Create or update the doctor record
        doctors[msg.sender].name = _name;
        doctors[msg.sender].age = _age;
        doctors[msg.sender].gender = _gender;
        doctors[msg.sender].specialty = _specialty;
        doctors[msg.sender].exists = true;

        // Emit the doctor record event
        emit DoctorRecord(msg.sender, _name, _age, _gender, _specialty);
    }

    // Function to get a doctor record
    function getDoctor(address _doctorAddress) public view returns (string memory, uint256, string memory, string memory) {
        // Check if the doctor record exists
        require(doctors[_doctorAddress].exists == true, "Doctor record does not exist");

        // Return the doctor record
        return (
            doctors[_doctorAddress].name,
            doctors[_doctorAddress].age,
            doctors[_doctorAddress].gender,
            doctors[_doctorAddress].specialty
        );
    }

    // Function to update a doctor record
    function updateDoctor(string memory _name, uint256 _age, string memory _gender, string memory _specialty) public {
        // Check if the doctor record exists
        require(doctors[msg.sender].exists == true, "Doctor record does not exist");

        // Update the doctor record
        doctors[msg.sender].name = _name;
        doctors[msg.sender].age = _age;
        doctors[msg.sender].gender = _gender;
        doctors[msg.sender].specialty = _specialty;

        // Emit the doctor record event
        emit DoctorRecord(msg.sender, _name, _age, _gender, _specialty);
    }

    // Function to delete a doctor record
    function deleteDoctor() public {
        // Check if the doctor record exists
        require(doctors[msg.sender].exists == true, "Doctor record does not exist");

        // Delete the doctor record
        delete doctors[msg.sender];

        // Emit the remove record event
        emit RemoveRecord(msg.sender);
    }

    // Function to authorize a doctor to access a patient record
    function authorizeDoctor(address _doctorAddress) public {
        // Check if the patient record exists
        require(patients[msg.sender].exists == true, "Patient record does not exist");

        // Check if the doctor record exists
        require(doctors[_doctorAddress].exists == true, "Doctor record does not exist");

        // Authorize the doctor to access the patient record
        patientDoctor[msg.sender][_doctorAddress] = true;

        // Update the patient record
        patients[msg.sender].isAuthorized = true;

        // Emit the authorize doctor event
        emit AuthorizeDoctor(msg.sender, _doctorAddress);
    }

    // Function to revoke a doctor's access to a patient record
    function revokeAccess(address _doctorAddress) public {
        // Check if the patient record exists
        require(patients[msg.sender].exists == true, "Patient record does not exist");

        // Check if the doctor record exists
        require(doctors[_doctorAddress].exists == true, "Doctor record does not exist");

        // Revoke the doctor's access to the patient record
        patientDoctor[msg.sender][_doctorAddress] = false;

        // Update the patient record
        patients[msg.sender].isAuthorized = false;

        // Emit the revoke access event
        emit RevokeAccess(msg.sender, _doctorAddress);
        }

    // Function to check if a doctor is authorized to access a patient record
    function isAuthorized(address _patientAddress, address _doctorAddress) public view returns (bool) {
        return patientDoctor[_patientAddress][_doctorAddress];
        }
}

