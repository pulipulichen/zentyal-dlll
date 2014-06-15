# 語法說明 http://www.lemoda.net/perl/perl-js/perl-js.html
# 線上編碼 http://www.compileonline.com/execute_perl_online.php

#escapeToUtf16: function (str) {
#    var escaped = "";
#    for (var i = 0; i < str.length; ++i) {
#        var hex = str.charCodeAt(i).toString(16).toUpperCase();
#        escaped += "+" + "0000".substr(hex.length) + hex;
#    }
#    return escaped;
#},
sub escapeToUtf16 {
    my ($str) = @_;
    my $escaped = "";
    #print $str;
    for (my $i = 0; $i < length $str; $i++) {
        #var hex = str.charCodeAt(i).toString(16).toUpperCase();
        #print $i;
        my $hex = ord(substr $str, $i, 1);
        $hex = sprintf("%X", $hex);
        $hex = uc $hex;

        
        #escaped += "+" + "0000".substr(hex.length) + hex;
        my $hex_length = length $hex;
        my $zero = substr "0000", 0, $hex_length;
        $escaped = $escaped . "+" . $zero . $hex;
    }
    return $escaped;
}

# Test
print "測試 escapeToUtf16:\n";
print escapeToUtf16("->p<測試>/p<-");
print "\n\n";

#convertUtf16CodesToString: function (utf16_codes) {
#    var unescaped = '';
#    for (var i = 0; i < utf16_codes.length; ++i) {
#        unescaped += String.fromCharCode(utf16_codes[i]);
#    }
#    return unescaped;
#},
sub convertUtf16CodesToString {
    my @utf16_codes = @_;
    
    my $unescaped = '';
    my $codes_length = @utf16_codes;
    print $codes_length . "\n";
    
    for (my $i = 0; $i < $codes_length; $i++) {
        #my $hex = chr(substr $utf16_codes, $i, 1);
        my $code = $utf16_codes[$i];
        #print $code . " - ";
        
        my $hex = chr($code);
        
        #print $hex . "\n";
        $unescaped = $unescaped . $hex;
    }
    return $unescaped;
}

#print convertUtf16CodesToString("+003C+0070+003E+00E6+00B8+00AC+00E8+00A9+00A6+003C+002F+0070+003E");

sub convertEscapedCodesToCodes {
    my ($str, $prefix, $base, $num_bits) = @_;

    # var parts = str.split(prefix);
    #print $str;
    #$prefix = '+';
    my @parts = split(/\+/, $str);

    # var codes = [];
    my @codes = ();

    # var max = Math.pow(2, num_bits);
    my $max = 1;
    for (my $i = 0; $i < $num_bits; $i++) {
        $max = $max * 2;
    }
    
    my $parts_length = @parts;
    #print $parts_length . "\n";
    #print $parts[1] . "\n";
    
    # for (var i = 0; i < parts.length; ++i) {
    for (my $i = 0; $i < $parts_length; $i++) {
        if ($parts[$i] ne "") {
          my $code = hex ($parts[$i]);
  
          if ($code >= 0 && $code < $max) {
              #print $code . "\n";
              push @codes, $code;
          }
        }
    }
    return @codes;
}

#convertEscapedCodesToCodes: function (str, prefix, base, num_bits) {
#    var parts = str.split(prefix);
#    parts.shift();
#    var codes = [];
#    var max = Math.pow(2, num_bits);
#    for (var i = 0; i < parts.length; ++i) {
#        var code = parseInt(parts[i], base);
#        if (code >= 0 && code < max) {
#            codes.push(code);
#        } else {
#        }
#    }
#    return codes;
#},

sub convertEscapedUtf16CodesToUtf16Codes {
    my (@str) = @_;
    return convertEscapedCodesToCodes(@str, "+", 16, 16);
}

#convertEscapedUtf16CodesToUtf16Codes: function (str) {
#    return this.convertEscapedCodesToCodes(str, "+", 16, 16);
#},

sub unescapeFromUtf16 {
    my ($str) = @_;
    my @utf16_codes = convertEscapedUtf16CodesToUtf16Codes($str);
    
    #my $len = @utf16_codes;
    #print $len;
    
    return convertUtf16CodesToString(@utf16_codes);
}

# 以下是真正的使用處！！！
print "測試 unescapeFromUtf16:\n";
#print unescapeFromUtf16("+003C+0070+003E+00E6+00B8+00AC+00E8+00A9+00A6+003C+002F+0070+003E");
print unescapeFromUtf16("+002D+003E+0070+003C+00E6+00B8+00AC+00E8+00A9+00A6+003E+002F+0070+003C+002D");

print "\n\n";
#print convertUtf16CodesToString("+003C+0070+003E+00E6+00B8+00AC+00E8+00A9+00A6+003C+002F+0070+003E");

#unescapeFromUtf16: function (str) {
#    var utf16_codes = this.convertEscapedUtf16CodesToUtf16Codes(str);
#    return this.convertUtf16CodesToString(utf16_codes);
#}