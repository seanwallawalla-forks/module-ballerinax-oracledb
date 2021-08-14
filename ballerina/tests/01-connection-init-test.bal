// Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied. See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/sql;
import ballerina/test;
import ballerina/file;

string clientStorePath = check file:getAbsolutePath("./tests/resources/keystore/client/client-keystore.p12");
string trustStorePath = check file:getAbsolutePath("./tests/resources/keystore/client/client-truststore.p12");

int SSLPORT = 2484;

// with user and password only
@test:Config {
    groups:["connection"]
}
isolated function testWithOnlyUserPasswordParams() {
    Client|sql:Error oracledbClient = new(user = USER, password = PASSWORD);
    test:assertTrue(oracledbClient is sql:Error, "Initializing only with username and password params should fail");
}

// with user, pwd, db
@test:Config {
    groups:["connection"]
}
isolated function testWithUserPasswordDatabaseParams() returns error? {
    Client oracledbClient = check new(user = USER, password = PASSWORD, database = DATABASE);
    test:assertEquals(oracledbClient.close(), (), "Initializing with username, password and database params fail");
}

// with all params except options
@test:Config {
    groups:["connection"]
}
isolated function testWithAllParamsExceptOptions() returns error? {
    Client oracledbClient = check new(
        host = HOST,
        user = USER, 
        password = PASSWORD,
        port = PORT,
        database = DATABASE
    );
    test:assertEquals(oracledbClient.close(), (), "Initializing with all params except options fail");
}

// with all params and options minus SSL
@test:Config {
    groups:["connection"]

}
function testWithOptionsExceptSSL() returns error? {
    Options options = {
        loginTimeout: 1,
        autoCommit: true,
        connectTimeout: 30,
        socketTimeout: 30
    };
    Client oracledbClient = check new(
        host = HOST,
        user = USER,
        password = PASSWORD,
        port = PORT,
        database = DATABASE,
        options = options);
    test:assertEquals(oracledbClient.close(), (), "Initializing with options fail");
}

// with all params, options and connection Pool
@test:Config {
   groups:["connection"]
}
function testWithConnectionPoolParam() returns error? {
    sql:ConnectionPool connectionPool = {
       maxOpenConnections: 10,
       maxConnectionLifeTime: 2000.0,
       minIdleConnections: 5
    };
    Client oracledbClient = check new(
        host = HOST,
        user = USER,
        password = PASSWORD,
        port = PORT,
        database = DATABASE,
        connectionPool = connectionPool
    );
    test:assertEquals(oracledbClient.close(), (), "Initializing with connection pool param fail");
}

// with all params and options with Erroneous SSL with wrong port
@test:Config {
    groups:["connection"]
}
function testWithOptionsWithErroneousSSL() returns error? {
     Options options = {
            ssl: {
                key: {
                    path: clientStorePath,
                    password: "password"
                },
                cert: {
                    path: trustStorePath,
                    password: "password"
                }
            }
     };
    Client|error oracledbClient = new(
        host = HOST,
        user = USER,
        password = PASSWORD,
        port = PORT,
        database = DATABASE,
        options = options
    );
    test:assertTrue(oracledbClient is error);
    if oracledbClient is sql:ApplicationError {
        test:assertTrue(oracledbClient.message().startsWith("Error in SQL connector configuration: Failed to initialize pool: " +
        "IO Error: closing inbound before receiving peer's close_notify"));
    } else {
        test:assertFail("Error ApplicatonError expected");
    }
}

// with all params and options with Erroneous SSL with correct port
@test:Config {
    groups:["connection"]
}
function testWithOptionsWithErroneousSSLCorrctPort() returns error? {
     Options options = {
            ssl: {
                key: {
                    path: clientStorePath,
                    password: "password"
                },
                cert: {
                    path: trustStorePath,
                    password: "password"
                }
            }
     };
    Client|error oracledbClient = new(
        host = HOST,
        user = USER,
        password = PASSWORD,
        port = SSLPORT,
        database = DATABASE,
        options = options
    );
    test:assertTrue(oracledbClient is error);
    if oracledbClient is sql:ApplicationError {
        test:assertTrue(oracledbClient.message().startsWith("Error in SQL connector configuration: Failed to initialize pool: " +
        "IO Error: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException"));
    } else {
        test:assertFail("Error ApplicatonError expected");
    }
}

// with all params and options with SSL with correct port with incorrect password
@test:Config {
    groups:["connection"]
}
function testWithOptionsWithErroneousSSLCorrctPortWrongPW() returns error? {
    string trustStorePathValid = check file:getAbsolutePath("./tests/resources/wallets/client-wallet/ballerina-server.p12");
         Options options = {
                ssl: {
                    cert: {
                        path: trustStorePathValid,
                        password: "InvalidPassword"
                    }
                }
         };
    Client|error oracledbClient = new(
        host = HOST,
        user = USER,
        password = PASSWORD,
        port = SSLPORT,
        database = DATABASE,
        options = options
    );
    test:assertTrue(oracledbClient is error);
    if oracledbClient is sql:ApplicationError {
        test:assertTrue(oracledbClient.message().endsWith("The Network Adapter could not establish the connection Caused by " +
        ":Unable to initialize ssl context."));
    } else {
        test:assertFail("Error ApplicatonError expected");
    }
}

// with all params and options with SSL cert only
@test:Config {
    groups:["connection"]
}
function testWithOptionsWithSSLWithoutKey() returns error? {
    string trustStorePathValid = check file:getAbsolutePath("./tests/resources/wallets/client-wallet/ballerina-server.p12");
     Options options = {
            ssl: {
                cert: {
                    path: trustStorePathValid,
                    password: "password"
                }
            }
     };
    Client oracledbClient = check new(
        host = HOST,
        user = USER,
        password = PASSWORD,
        port = SSLPORT,
        database = DATABASE,
        options = options
    );
    test:assertEquals(oracledbClient.close(), (), "Initializing with ssl param fail");
}

// with all params and options with SSL both key and cert
@test:Config {
    groups:["connection"]
}
function testWithOptionsWithSSLWitKey() returns error? {
    string clientStorePathValid = check file:getAbsolutePath("./tests/resources/wallets/client-wallet/ballerina-client.p12");
    string trustStorePathValid = check file:getAbsolutePath("./tests/resources/wallets/client-wallet/ballerina-server.p12");
     Options options = {
            ssl: {
                key: {
                    path: clientStorePathValid,
                    password: "password@123"
                },
                cert: {
                    path: trustStorePathValid,
                    password: "password"
                }
            }
     };
    Client oracledbClient = check new(
        host = HOST,
        user = USER,
        password = PASSWORD,
        port = SSLPORT,
        database = DATABASE,
        options = options
    );
    test:assertEquals(oracledbClient.close(), (), "Initializing with ssl params fail");
}
