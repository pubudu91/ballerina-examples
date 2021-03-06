import ballerina/io;
import ballerina/log;
import ballerina/http;

@http:WebSocketServiceConfig {
    path: "/basic/ws",
    subProtocols: ["xml", "json"],
    idleTimeoutInSeconds: 120
}
service<http:WebSocketService> basic bind { port: 9090 } {

    string ping = "ping";
    blob pingData = ping.toBlob("UTF-8");

    // This resource is triggered after a successful client connection.
    onOpen(endpoint caller) {
        io:println("\nNew client connected");
        io:println("Connection ID: " + caller.id);
        io:println("Negotiated Sub protocol: " + caller.negotiatedSubProtocol);
        io:println("Is connection open: " + caller.isOpen);
        io:println("Is connection secured: " + caller.isSecure);
    }

    // This resource is triggered when a new text frame is received from a client.
    onText(endpoint caller, string text, boolean final) {
        io:println("\ntext message: " + text + " & final fragment: " + final);

        if (text == "ping") {
            io:println("Pinging...");
            caller->ping(pingData) but { error e => log:printError("Error sending ping", err = e) };
        } else if (text == "closeMe") {
            caller->close(1001, "You asked me to close the connection")
            but { error e => log:printError("Error occurred when closing the connection", err = e) };
        } else {
            caller->pushText("You said: " + text) but { error e => log:printError("Error occurred when sending text",
                err = e) };
        }
    }

    // This resource is triggered when a new binary frame is received from a client.
    onBinary(endpoint caller, blob b) {
        io:println("\nNew binary message received");
        io:println("UTF-8 decoded binary message: " + b.toString("UTF-8"));
        caller->pushBinary(b) but { error e => log:printError("Error occurred when sending binary", err = e) };
    }

    // This resource is triggered when a ping message is received from the client. If this resource is not implemented,
    // a pong message is automatically sent to the connected endpoint when a ping is received.
    onPing(endpoint caller, blob data) {
        caller->pong(data) but { error e => log:printError("Error occurred when closing the connection", err = e) };
    }

    // This resource is triggered when a pong message is received.
    onPong(endpoint caller, blob data) {
        io:println("Pong received");
    }

    // This resource is triggered when a particular client reaches the idle timeout that is defined in the
    // `http:WebSocketServiceConfig` annotation.
    onIdleTimeout(endpoint caller) {
        io:println("\nReached idle timeout");
        io:println("Closing connection " + caller.id);
        caller->close(1001, "Connection timeout") but {
            error e => log:printError("Error occured when closing the connection", err = e)
        };
    }

    // This resource is triggered when a client connection is closed from the client side.
    onClose(endpoint caller, int statusCode, string reason) {
        io:println("\nClient left with status code " + statusCode + " because " + reason);
    }
}
