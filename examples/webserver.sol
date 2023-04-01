// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

struct RequestQueryParam {
    string Key;
    string Value;
}

enum HeaderOption {
    Undefined,            // if option is 0, it means it is unset
    Proto,                // "HTTP/1.1"
    ProtoMajor,           // 1
    ProtoMinor,           // 1
    RequestMethod,        // "GET"
    HttpHost,             // "example.com"
    PathInfo,             // "/foo/bar"
    QueryString,          // "var1=value1&var2=with%20percent%20encoding"
    Location,             // Indicates the URL to redirect a page to.
    ContentType,          // Content-Type            // "text/html; charset=UTF-8" Indicates the media type of the resource.
    ContentEncoding,      // Content-Encoding        // Used to specify the compression algorithm.
    ContentLanguage,      // Content-Language        // "en" Describes the human language(s) intended for the audience, so that it allows a user to differentiate according to the users' own preferred language.
    ContentLength,        // "0" Content-Length          // The size of the resource, in decimal number of bytes.
    ContentLocation,       // "/" Content-Location
    Status,               // "200 OK"
    StatusCode,           //  200
    WWWAuthenticate,      // WWW-Authenticate        // Defines the authentication method that should be used to access a resource.
    Authorization,        //Authorization           // Contains the credentials to authenticate a user-agent with a server.
    AuthType,
    Accept,               //
    Connection,           //   Controls whether the network connection stays open after the current transaction finishes; "close"
    KeepAlive,            // Keep-Alive              // Controls how long a persistent connection should stay open.
    Cookie,               // Cookie                  // Contains stored HTTP cookies previously sent by the server with the Set-Cookie header.
    SetCookie,            // Set-Cookie              // Send cookies from the server to the user-agent.
    AccessControlAllowOrigin,  // Access-Control-Allow-Origin   // Indicates whether the response can be shared.
    Server,               // "Mythos"
    RemoteAddr,
    ServerPort,           // "80"
    AcceptPushPolicy,     // Accept-Push-Policy      // A client can express the desired push policy for a request by sending an Accept-Push-Policy header field in the request.
    AcceptSignature      // Accept-Signature        // A client can send the Accept-Signature header field to indicate intention to take advantage of any available signatures and to indicate what kinds of signatures it supports.
}

struct HeaderItem {
    HeaderOption HeaderType;
    string Value;
}

struct HttpRequest {
    HeaderItem[] Header;
    RequestQueryParam[] QueryParams;
}

struct HttpResponse {
    HeaderItem[] Header;
    string Content;
}

contract CGI {
    // 2b6b3f70 "get(((uint8,string)[],(string,string)[]))"
    function get(HttpRequest memory request) virtual public view returns (HttpResponse memory) {}

    // 41e1f9a4 "post(((uint8,string)[],(string,string)[]))"
    function post(HttpRequest memory request) virtual public payable returns (HttpResponse memory) {}

    function getHeaderValue(
        HeaderItem[] memory header,
        HeaderOption headerType
    ) public pure returns (string memory value) {
        for (uint256 i = 0; i < header.length; i++) {
            if (header[i].HeaderType == headerType) {
                value = header[i].Value;
                break;
            }
        }
        return value;
    }
}

contract SimpleServer is CGI {
    string public sitepage;
    string public contentType;
    address public owner;

    constructor(string memory content, string memory content_type) {
        owner = msg.sender;
        sitepage = content;
        contentType = content_type;
    }

    function setPage(string memory content, string memory content_type) public {
        require(msg.sender == owner, "not owner");
        sitepage = content;
        contentType = content_type;
    }

    function getPage() public view returns (string memory) {
        return sitepage;
    }

    function get(HttpRequest memory request)
        override public view returns (HttpResponse memory)
    {
        HeaderItem[] memory headers = new HeaderItem[](1);
        headers[0] = HeaderItem(HeaderOption.ContentType, contentType);
        HttpResponse memory response = HttpResponse(headers, sitepage);
        return response;
    }
}

contract SimpleServer2 is CGI {
    function get(HttpRequest memory request)
        override public view returns (HttpResponse memory)
    {
        string memory urlPath = getHeaderValue(request.Header, HeaderOption.PathInfo);
        HeaderItem[] memory headers = new HeaderItem[](1);
        headers[0] = HeaderItem(HeaderOption.ContentType, "text/html");
        HttpResponse memory response = HttpResponse(headers, getCurrentState());
        return response;
    }

    function getState() public view returns (uint256, uint256, uint256) {
        return (block.chainid, block.number, block.timestamp);
    }

    // chainid, block, timestamp, proposer
    function getCurrentState() public view returns (string memory) {
        string memory state = string(abi.encodePacked(
            "<!DOCTYPE html>\n<html>\n<div>"
            "<p>Chain id: ", uint2str(block.chainid), "</p>",
            "<p>Last block: ", uint2str(block.number), "</p>",
            "<p>Block timestamp: ", uint2str(block.timestamp), "</p>",
            "<p>Block coinbase: ", addressToString(block.coinbase), "</p>",
            "</div></html>"
        ));
        return state;
    }

    function uint2str(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function addressToString(address addr) public pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory _SYMBOLS = "0123456789abcdef";
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
