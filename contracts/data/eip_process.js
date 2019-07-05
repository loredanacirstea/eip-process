const DEPLOY_ARGS = {
    eipBaseUrl: "https://github.com/ethereum/EIPs/pull/",
    statuses: ["draft", "last call", "accepted", "final", "abandoned"],
    categories: ["core", "networking", "interface", "erc", "meta", "informational"],
    editors: [
        ["0xca35b7d915458ef540ade6068dfe2f44e8fa733c", [0, 1, 3]],
        ["0x14723a09acff6d2a60dcdf7aa4aff308fddc160c", [2]],
        ["0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db", [3, 4, 5]],
        ["0x583031d1113ad414f02576bd6afabfb302140225", [3]],
        ["0xdd870fa1b7c4700f2bd7f44238821c26f7392148", [3]]
    ]
}

module.exports = {
    DEPLOY_ARGS,
}
