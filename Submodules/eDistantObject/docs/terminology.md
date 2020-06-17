# Terminology

## Host/Remote process

The host process refers to the process which receives the remote call and runs
the executor. It is also used as a remote process.

## Client process

The client process refers to the process where the remote call originates from.

## Shared Header

The user’s code implements the actual methods or features that will be running
in the host process. Only its headers need to be exposed to both the client and the host.

## Client code

The source code that is written for the client process, where it would make a
remote call.

## Host/Client connection

The host refers to the socket that listens on the port, and the client refers to
the socket that connects to the host.
