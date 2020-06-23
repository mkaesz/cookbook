#!/bin/sh

%{ for s in servers ~}
nameserver ${s}
%{ endfor ~}

%{ for s in clients ~}
nameserver ${s}
%{ endfor ~}
