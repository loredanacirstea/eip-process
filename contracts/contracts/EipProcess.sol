pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

contract EipProcess {

    string public eipBaseUrl;

    uint8[] public statusCodes;
    uint8[] public categoryCodes;
    // encoded names
    mapping(uint8 => string) public statusNames;
    mapping(uint8 => string) public categoryNames;

    // TODO: status transition correctness
    // mapping(uint8 => uint8[]) statusAllowedTransitions;

    uint16 public editorCounter;
    mapping(uint16 => Editor) public editors;
    mapping(address => uint16) public editorCodes;
    // categoryCode => editorCodes
    mapping(uint16 => uint16[]) freeEditors;

    uint32 public eipCounter;
    mapping(uint32 => EIP) public eips;

    // encoded metadata
    // mapping(uint32 => bytes) public eipExtraData;

    // if no editors are found
    // uint32[] public awaitingFreeEditor;

    uint8 public constant maxEipsDefault = 30;

    event StatusChangeRequest(uint32 indexed eipCode, uint8 indexed status);
    event StatusChanged(uint32 indexed eipCode, uint8 indexed newstatus);
    event StatusChangeChallenge(uint32 indexed eipCode, uint8 currentStatus, uint8 proposedStatus);
    event AuthorChanged(uint32 indexed eipCode, address author);
    event EditorChanged(uint32 indexed eipCode, address editor);
    event EditorAdded(address indexed editor);
    event EditorRemoved(address indexed editor);
    event NoAvailableEditor();

    struct EIP {
        uint8 status;
        uint16 editor;
        uint8 priority;  // set by currentEditor
        address author;
        uint256 lastStatusChangeBlock;
    }

    struct Editor {
        uint8 currentEips;
        uint8 maxEips;
        uint8[] categories;
    }

    struct EditorInit {
        address editor;
        uint8[] categories;
    }

    modifier isEditor() {
        require(editorCodes[msg.sender] > 0);
        _;
    }

    modifier isCurrentEditor(uint32 eipCode) {
        uint16 editor = editorCodes[msg.sender];
        require(editor > 0);
        require(eips[eipCode].editor == editor);
        _;
    }

    modifier isAuthor(uint32 eipCode) {
        require(eips[eipCode].author == msg.sender);
        _;
    }

    modifier isCategory(uint8 categoryCode) {
        require(bytes(categoryNames[categoryCode]).length > 0);
        _;
    }

    modifier isEip(uint32 eipCode) {
        require(eips[eipCode].status > 0);
        _;
    }

    constructor (string memory _eipBaseUrl, string[] memory _statuses, string[] memory _categories, EditorInit[] memory _editors) public {
        eipBaseUrl = _eipBaseUrl;
        addStatusesPrivate(_statuses);
        addCategoriesPrivate(_categories);

        address[] memory removedEditors;
        changeEditorsPrivate(_editors,removedEditors);
    }

    function changeEditors(EditorInit[] memory addedEditors, address[] memory removedEditors) public isEditor {
        changeEditorsPrivate(addedEditors, removedEditors);
    }

    function addStatuses(string[] memory _statuses) isEditor public {
        addStatusesPrivate(_statuses);
    }

    function addCategories(string[] memory _categories) isEditor public {
        addCategoriesPrivate(_categories);
    }

    function setEditorMaxEips(uint8 _maxEips) isEditor public {
        editors[editorCodes[msg.sender]].maxEips = _maxEips;
    }

    function addEip(uint32 eipCode, uint8 categoryCode) isCategory(categoryCode) public {
        if (freeEditors[categoryCode].length == 0) {
            emit NoAvailableEditor();
        } else {
            // Choose "random" editor
            uint8 editorsInCat = uint8(freeEditors[categoryCode].length) - 1;
            uint16 randomFreeEditorIndex = random(editorsInCat);
            uint16 editorCode = freeEditors[categoryCode][randomFreeEditorIndex];

            // Set EIP
            eips[eipCode] = EIP(1, editorCode, 0, msg.sender, block.number);

            // Increase editor's in review eips
            editors[editorCode].currentEips += 1;

            // Remove editor from freeEditors if he reached maxEips in review
            if (editors[editorCode].currentEips >= editors[editorCode].maxEips) {
                unfreeEditor(editorCode);
            }
            emit StatusChangeRequest(eipCode, 1);
            // TODO: author should provide ETH/gas for editor transactions
        }
    }

    function setEipPriority(uint32 eipCode, uint8 _priority) isEip(eipCode) isCurrentEditor(eipCode) public {
        eips[eipCode].priority = _priority;
    }

    function changeEipStatus(uint32 eipCode, uint8 statusCode, bool finalized) isCurrentEditor(eipCode) public {
        eips[eipCode].status = statusCode;

        // If Final, subtract eip from editor; if editor not free, make him free
        if (finalized == true) {
            uint16 editorCode = eips[eipCode].editor;
            editors[editorCode].currentEips -= 1;
            if (editors[editorCode].currentEips + 1 == editors[editorCode].maxEips) {
                freeEditor(editorCode);
            }
        }
        emit StatusChanged(eipCode, statusCode);
    }

    function statusRequest(uint32 eipCode, uint8 newStatus) isAuthor(eipCode) public {
        emit StatusChangeRequest(eipCode, newStatus);
    }

    // Anyone can call this
    function statusChallenge(uint32 eipCode, uint8 proposedStatus) public {
        emit StatusChangeChallenge(eipCode, eips[eipCode].status, proposedStatus);
    }

    function changeAuthor(uint32 eipCode, address newAuthor) public {
        // if author or currentEditor
    }

    function changeEditor(uint32 eipCode, address newEditor) public {
        // only currentEditor or at least 2 editors (signatures)
    }

    function changeEditorsPrivate(EditorInit[] memory addedEditors, address[] memory removedEditors) private {
        // Add editors
        for (uint8 i = 0; i < addedEditors.length; i++) {
            if (editorCodes[addedEditors[i].editor] == 0) {
                editorCounter += 1;
                editors[editorCounter] = Editor(0, maxEipsDefault, addedEditors[i].categories);
                editorCodes[addedEditors[i].editor] = editorCounter;
                // Add editor as free
                for (uint8 cat; cat < addedEditors[i].categories.length; cat++) {
                    freeEditors[addedEditors[i].categories[cat]].push(editorCounter);
                }
                emit EditorAdded(addedEditors[i].editor);
            }
        }
        // TODO removedEditors from freeEditors; for now, they are not removed entirely
        // emit EditorRemoved
    }

    function addStatusesPrivate(string[] memory _statuses) private {
        for (uint8 i = 0; i < _statuses.length; i++) {
            uint8 statusCode = uint8(statusCodes.length);
            statusCodes.push(statusCode);
            statusNames[statusCode] = _statuses[i];
        }
    }

    function addCategoriesPrivate(string[] memory _categories) private {
        for (uint8 i = 0; i < _categories.length; i++) {
            uint8 categoryCode = uint8(categoryCodes.length);
            categoryCodes.push(categoryCode);
            categoryNames[categoryCode] = _categories[i];
        }
    }

    function unfreeEditor(uint16 editorCode) private {
        uint8[] memory categories = editors[editorCode].categories;
        for (uint8 i = 0; i < categories.length; i++) {
            uint16[] storage free = freeEditors[categories[i]];
            for (uint16 j = 0; j < free.length; j++) {
                if (free[free[i]] == editorCode) {
                    free[free[i]] = free[uint16(free.length) - 1];
                    free.pop();
                }
            }
        }
    }

    function freeEditor(uint16 editorCode) private {
        uint8[] memory categories = editors[editorCode].categories;
        for (uint8 i = 0; i < categories.length; i++) {
            freeEditors[categories[i]].push(editorCode);
        }
    }

    function getUrl(uint32 eipCode) view public returns(string memory url) {
        return string(abi.encodePacked(eipBaseUrl, eipCode));
    }

    function random(uint16 max) public view returns (uint16) {
        return uint16(uint256(keccak256(abi.encodePacked( block.timestamp, block.difficulty)))%max);
    }

}
