const EipProcess = artifacts.require("EipProcess");
const BN = web3.utils.BN;
const DATA = require('../data/eip_process.js');

contract('EipProcess', async (accounts) => {
    let eipp, eip;

    it('check deployed', async () => {
        eipp = await EipProcess.deployed();

        assert.equal(await eipp.maxEipsDefault(), 30, 'wrong maxEipsDefault');
    });

    it('check deployed args', async () => {
        assert.equal(await eipp.eipBaseUrl(), DATA.DEPLOY_ARGS.eipBaseUrl, 'eipBaseUrl wrong');
        assert.sameOrderedMembers(await eipp.getStatuses(), DATA.DEPLOY_ARGS.statuses, 'statuses wrong');
        assert.sameOrderedMembers(await eipp.getCategories(), DATA.DEPLOY_ARGS.categories, 'categories wrong');

        for (editor of DATA.DEPLOY_ARGS.editors) {
            let editorCode = await eipp.editorCodes(editor[0]);
            assert.isOk(editorCode.gt(new BN(0)), 'editor not inserted');

            let editorStruct = await eipp.getEditor(editorCode);
            assert.equal(editorStruct.currentEips, 0, 'currentEips wrong');
            assert.equal(editorStruct.maxEips, 30, 'maxEips wrong');
            assert.sameOrderedMembers(editorStruct.categories.map(i => parseInt(i)), editor[1], 'categories wrong');

            // Check editor is listed as free
            for (categ of editor[1]) {
                assert.include((await eipp.getFreeEditors(categ)).map(i => i.toNumber()), editorCode.toNumber());
            }
        }
    });

    it ('test EIP add process', async () => {
        let currentEditorEips;

        // Add EIP
        await eipp.addEip(1900, 3, {from: accounts[1]});
        eip = await eipp.eips(1900);

        assert.equal(eip.status, 1, 'wrong status');
        assert.isOk(eip.editor.gt(new BN(0)), 'no editor assigned');
        assert.equal(eip.priority, 0, 'wrong priority');
        assert.equal(eip.author, accounts[1], 'wrong author');
        // TODO assert.equal(eip.lastStatusChangeBlock, 1, 'wrong lastStatusChangeBlock');
        assert.equal(await eipp.getEipUrl('1900'), DATA.DEPLOY_ARGS.eipBaseUrl + 1900, 'wrong EIP url');

        // Editor's currentEips increase with 1
        currentEditorEips = (await eipp.getEditor(eip.editor)).currentEips;
        assert.equal(currentEditorEips, 1, 'wrong currentEips');

        // Editor setEipPriority
    });

    it ('test EIP status changed', async () => {
        // statusRequest
        // changeEipStatus
    });

    it ('test EIP status challenge', async () => {
        // statusChallenge
    });

    it ('test EIP author changed', async () => {

    });

    it ('test EIP editor changed', async () => {

    });

    it ('test editor add/remove', async () => {

    });

    it ('test editor setEditorMaxEips', async () => {

    });

    it ('test no available editor', async () => {

    });
});
