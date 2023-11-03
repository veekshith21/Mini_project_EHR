// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract EHR {
    // Define EHR contract functions and data here
    // Patient struct
    struct Patient {
        address patientaddress;
        string name;
        uint256 age;
        Record[] records;
    }

    // Doctor struct
    struct Doctor {
        address doctoraddress;
        string name;
        uint256 age;
        string gender;
        DoctorProfile[] profile;
        bool exists;
    }

    // Doctor profile struct
    struct DoctorProfile {
        string specialty;
    }

    // Record struct
    struct Record {
        string cid;
        string name;
        uint256 age;
        string gender;
        string diagnosis;
        string prescription;
        address patientaddress;
        address doctoraddress;
        uint256 timeAdded;
    }

    address public owner;
    address[] public doctorsList;
    constructor() {
        owner = msg.sender;
    }

    // Mapping of patient addresses to their record
    mapping(address => Patient) private patients;

    // Mapping of doctor addresses to their record
    mapping(address => Doctor) private doctors;

    // Mapping of patient addresses to their authorized doctors
    mapping(address => mapping(address => bool)) private patientDoctor;

    event PatientAdded(address patientaddress, string name, uint256 age);
    event DoctorAdded(address doctoraddress, string name, uint256 age, string gender, string specialty);
    event RecordAdded(string cid, string name, uint256 age, string gender, string diagnosis, string prescription, address patientaddress, address doctoraddress); 
    event PatientRecord(address indexed patientAddress, string name, uint256 age, string gender, string diagnosis, string prescription);
    event DoctorRecord(address indexed doctorAddress, string name, uint256 age, string gender, string specialty);
    event AuthorizeDoctor(address indexed patientAddress, address indexed doctorAddress);
    event RevokeAccess(address indexed patientAddress, address indexed doctorAddress);
    event RecordDeleted(string cid, address patientaddress, address doctoraddress);
    event DoctorRemoved(address indexed doctorAddress);

    modifier senderExists {
        require(doctors[msg.sender].doctoraddress == msg.sender || patients[msg.sender].patientaddress == msg.sender, "Sender does not exist");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }


    modifier patientExists(address _patientaddress) {
        require(patients[_patientaddress].patientaddress == _patientaddress, "Patient does not exist");
        _;
    }

    modifier senderIsDoctor {
        require(doctors[msg.sender].doctoraddress == msg.sender, "Sender is not a doctor");
        _;
    }

    function addPatient(address _patientaddress, string memory _name, uint256 _age) public senderIsDoctor {
        require(patients[_patientaddress].patientaddress != _patientaddress, "This patient already exists.");
        patients[_patientaddress].patientaddress = _patientaddress;
        patients[_patientaddress].name = _name;
        patients[_patientaddress].age = _age;
        emit PatientAdded(_patientaddress, _name, _age);
    }

    function addDoctor(address _doctoraddress,string memory _name, uint256 _age, string memory _gender, string memory _specialty) public {
        require(doctors[msg.sender].doctoraddress != msg.sender, "This doctor already exists.");
        doctors[msg.sender].doctoraddress = msg.sender;
        doctors[msg.sender].name = _name;
        doctors[msg.sender].age = _age;
        doctors[msg.sender].gender = _gender;
        
        DoctorProfile memory profile = DoctorProfile(_specialty);
        doctors[_doctoraddress].profile.push(profile);

        doctors[msg.sender].exists = true;
        doctorsList.push(msg.sender); // Add the doctor's address to the doctorsList array

        emit DoctorAdded(msg.sender,_name, _age, _gender, _specialty);
    }
    //

    function removeDoctor(address _doctorAddress) public onlyOwner {
        require(doctors[_doctorAddress].exists == true, "This doctor does not exist.");
        delete doctors[_doctorAddress];
        for (uint i = 0; i < doctorsList.length; i++) {
            if (doctorsList[i] == _doctorAddress) {
                delete doctorsList[i]; // Remove the doctor's address from the doctorsList array
                break;
            }
        }
        emit DoctorRemoved(_doctorAddress);
    }

//
    function getDoctorDetails(address _doctorAddress) public view returns (string memory name, uint256 age, string memory gender, DoctorProfile[] memory specialty) {
        require(doctors[_doctorAddress].exists == true, "This doctor does not exist.");
        name = doctors[_doctorAddress].name;
        age = doctors[_doctorAddress].age;
        gender = doctors[_doctorAddress].gender;
        specialty = doctors[_doctorAddress].profile;
    }

//
    function getDoctorAddressByName(string memory _name) public view returns (address) {
        for (uint i = 0; i < doctorsList.length; i++) {
            if (keccak256(bytes(doctors[doctorsList[i]].name)) == keccak256(bytes(_name))) {
                return doctorsList[i];
            }
        }
        revert("Doctor not found.");
    }


    function editDoctorSpecialty(address _doctorAddress, string memory _specialty, uint256 _profileIndex) public {
        Doctor storage doctor = doctors[_doctorAddress];
        require(doctor.exists, "Doctor does not exist");
        require(_profileIndex < doctor.profile.length, "Invalid profile index");
        DoctorProfile storage profile = doctor.profile[_profileIndex];
        profile.specialty = _specialty;
    }


     // Function to create record
    function createRecord(string memory _cid, string memory _name,  uint256 _age, string memory _gender, string memory _diagnosis, string memory _prescription, address _patientaddress) public senderIsDoctor patientExists(_patientaddress) {
        Record memory record = Record(_cid, _name, _age, _gender, _diagnosis, _prescription, _patientaddress, msg.sender, block.timestamp);
        patients[_patientaddress].records.push(record);

        emit RecordAdded(_cid, _name, _age, _gender, _diagnosis, _prescription, _patientaddress, msg.sender);
    } 

    function getRecords(address _patientaddress) public view senderExists patientExists(_patientaddress) returns (Record[] memory) {
        return patients[_patientaddress].records;
    } 

    //using access control
    // Function to update a patient record using index
    // suppose you want to update the second record for a patient _index = 1.
    function updateRecord(string memory _cid, string memory _name,  uint256 _age, string memory _gender, string memory _diagnosis, string memory _prescription, address _patientaddress,  uint256 _index) public senderIsDoctor patientExists(_patientaddress){
        require(_index < patients[_patientaddress].records.length, "Invalid index");

        Record storage record = patients[_patientaddress].records[_index];
        require(record.doctoraddress == msg.sender, "Only the doctor who added the record can update it");

        record.cid = _cid;
        record.name = _name;
        record.age = _age;
        record.gender = _gender;
        record.diagnosis = _diagnosis;
        record.prescription = _prescription;
        record.patientaddress = _patientaddress;

        emit RecordAdded(_cid, _name, _age, _gender, _diagnosis, _prescription, _patientaddress, msg.sender);
    }

    // Function to delete a patient record
    function deleteRecord(address _patientaddress, uint256 _index) public senderIsDoctor patientExists(_patientaddress) {
        require(_index < patients[_patientaddress].records.length, "Invalid index");

        Record storage record = patients[_patientaddress].records[_index];
        require(record.doctoraddress == msg.sender, "Only the doctor who added the record can delete it");

        // Move the last element of the array to the position being deleted
        uint256 lastIndex = patients[_patientaddress].records.length - 1;
        Record storage lastRecord = patients[_patientaddress].records[lastIndex];
        patients[_patientaddress].records[_index] = lastRecord;

        // Remove the last element of the array
        patients[_patientaddress].records.pop();

        emit RecordDeleted(record.cid, _patientaddress, msg.sender);
    }


    // Define an instance of the AppointmentManager contract
    AppointmentManager  appointmentManager;

    // Define a function to set the AppointmentManager contract address
    function setAppointmentManager(address _appointmentManager) public onlyOwner {
        require(_appointmentManager != address(0), "Invalid appointment manager address.");
        appointmentManager = AppointmentManager(_appointmentManager);
    }
}

contract Ownable {      //admin
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
}
contract AppointmentManager is Ownable {
  
    // Define AppointmentManager contract functions and data here
    enum AppointmentStatus { Pending, Approved, Rejected }

    struct Appointment {
        uint256 id;
        address patient;
        address doctor;
        uint256 date;
        AppointmentStatus status;
        string rejectReason;
    }

    //calculate the Unix timestamp for this date using an online converter or programming library
    //Wednesday, May 10, 2023 6:30:30 AM == 1683700230
    mapping(uint256 => Appointment) public appointments;
    uint256 public lastAppointmentId;

    event AppointmentCreated(uint256 id, address patient, address doctor, uint256 date);
    event AppointmentApproved(uint256 id);
    event AppointmentRejected(uint256 id, string reason);

    //
    function createAppointment(address _patient, address _doctor, uint256 _date) public {
        require(_patient != address(0), "Invalid patient address.");
        require(_doctor != address(0), "Invalid doctor address.");
        require(_date > block.timestamp, "Invalid appointment date.");

        lastAppointmentId++;
        appointments[lastAppointmentId] = Appointment(lastAppointmentId, _patient, _doctor, _date, AppointmentStatus.Pending, "");
        emit AppointmentCreated(lastAppointmentId, _patient, _doctor, _date);
    }

    //
    function approveAppointment(uint256 _appointmentId) public onlyOwner {
        require(appointments[_appointmentId].status == AppointmentStatus.Pending, "Appointment is not pending.");
        appointments[_appointmentId].status = AppointmentStatus.Approved;
        emit AppointmentApproved(_appointmentId);
    }

    //
    function rejectAppointment(uint256 _appointmentId, string memory _reason) public onlyOwner {
        require(appointments[_appointmentId].status == AppointmentStatus.Pending, "Appointment is not pending.");
        appointments[_appointmentId].status = AppointmentStatus.Rejected;
        appointments[_appointmentId].rejectReason = _reason;
        emit AppointmentRejected(_appointmentId, _reason);
    }
}