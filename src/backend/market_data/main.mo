import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import IC "ic:aaaaa-aa";
import Blob "mo:base/Blob";
import Cycles "mo:base/ExperimentalCycles";
import Iter "mo:base/Iter";

actor MarketData {
    type http_header = {
        name: Text;
        value: Text;
    };

    type http_response = {
        status: Nat;
        headers: [http_header];
        body: Blob;
    };

    type http_request_result = {
        status: Nat;
        headers: [http_header];
        body: Blob;
    };

    type TransformContext = {
        function: shared query ({context: Blob; response: http_request_result}) -> async http_request_result;
        context: Blob;
    };

    type CanisterHttpRequestArgs = {
        url: Text;
        max_response_bytes: ?Nat64;
        headers: [http_header];
        body: ?Blob;
        method: {#get; #post; #head};
        transform: ?{
            function: shared query ({context: Blob; response: http_request_result}) -> async http_request_result;
            context: Blob;
        };
    };

    // Cache market data to avoid too frequent calls
    private let priceCache = HashMap.HashMap<Text, (Float, Int)>(10, Text.equal, Text.hash);
    private let CACHE_DURATION = 60_000_000_000; // 1 minute in nanoseconds

    public func getPrice(symbol: Text) : async Result.Result<Float, Text> {
        // Check cache first
        switch(priceCache.get(symbol)) {
            case (?(price, timestamp)) {
                if (Time.now() - timestamp < CACHE_DURATION) {
                    return #ok(price);
                };
            };
            case null {};
        };

        // Prepare HTTP request to CoinGecko API
        let request: CanisterHttpRequestArgs = {
            url = "https://api.coingecko.com/api/v3/simple/price?ids=" # symbol # "&vs_currencies=usd";
            max_response_bytes = ?2048;
            headers = [
                { name = "Host"; value = "api.coingecko.com:443" },
                { name = "User-Agent"; value = "market_data_canister" }
            ];
            body = null;
            method = #get;
            transform = ?{
                function = transform;
                context = Text.encodeUtf8("price");
            };
        };

        try {
            Cycles.add(230_949_972_000);
            let ic : actor { 
                http_request : CanisterHttpRequestArgs -> async http_response;
            } = actor("aaaaa-aa");
            
            let response = await ic.http_request(request);
            if (response.status != 200) {
                return #err("HTTP request failed with status: " # debug_show(response.status));
            };

            let price = parsePrice(response.body);
            priceCache.put(symbol, (price, Time.now()));
            #ok(price)
        }
        catch(error) {
            #err("Failed to fetch price: " # Error.message(error))
        }
    };

    public shared query func transform(args: {context: Blob; response: http_request_result}) : async http_request_result {
        {
            status = args.response.status;
            headers = [
                { name = "Content-Type"; value = "application/json" },
                { name = "Content-Security-Policy"; value = "default-src 'self'" },
                { name = "Strict-Transport-Security"; value = "max-age=63072000" }
            ];
            body = args.response.body;
        }
    };

    private func parsePrice(responseBody: Blob) : Float {
        let decoded_text = switch (Text.decodeUtf8(responseBody)) {
            case (null) { return 0.0 };
            case (?text) { text };
        };
        
        // For demo, returning a mock price
        // TODO: Implement proper JSON parsing
        45000.00
    };

    // Technical indicators
    public func getRSI(symbol: Text, period: Nat) : async Result.Result<Float, Text> {
        let request: CanisterHttpRequestArgs = {
            url = "https://api.taapi.io/rsi?secret=demo&symbol=" # symbol # "&interval=" # debug_show(period);
            max_response_bytes = ?2048;
            headers = [];
            body = null;
            method = #get;
            transform = null;
        };

        try {
            let response = await IC.http_request(request);
            if (response.status != 200) {
                return #err("Failed to get RSI");
            };
            
            // Parse RSI value from response
            // For demo, returning mock RSI
            #ok(65.5)
        }
        catch(error) {
            #err("Failed to fetch RSI: " # Error.message(error))
        }
    };

    public func getMACD(symbol: Text) : async Result.Result<(Float, Float), Text> {
        let request: CanisterHttpRequestArgs = {
            url = "https://api.taapi.io/macd?secret=demo&symbol=" # symbol;
            max_response_bytes = ?2048;
            headers = [];
            body = null;
            method = #get;
            transform = null;
        };

        try {
            let response = await IC.http_request(request);
            if (response.status != 200) {
                return #err("Failed to get MACD");
            };
            
            // Parse MACD values from response
            // For demo, returning mock MACD values (MACD line, Signal line)
            #ok((245.5, 248.2))
        }
        catch(error) {
            #err("Failed to fetch MACD: " # Error.message(error))
        }
    };
} 