module.exports = {
    // Uncommenting the defaults below
    // provides for an easier quick-start with Ganache.
    // You can also follow this format for other networks;
    // see <http://truffleframework.com/docs/advanced/configuration>
    // for more details on how to specify configuration options!
    //
    networks: {
        local: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*",
            from: "0x2dbe6a7c756851b5239a118c71e16c95e33ecda8",
            gas: "3141592"
        },
        //  development: {
        //    host: "127.0.0.1",
        //    port: 7545,
        //    network_id: "*"
        //  },
        //  test: {
        //    host: "127.0.0.1",
        //    port: 7545,
        //    network_id: "*"
        //  }
    },
    //
    compilers: {
        solc: {
            version: "native", // TODO: docker image
            docker: false, // Use a version obtained through docker
            parser: "solcjs",
        }
    }
};
