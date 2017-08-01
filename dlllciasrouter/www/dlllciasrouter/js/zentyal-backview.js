$(function () {
    var getQueryVariable = function (variable) {
        var query = window.location.search.substring(1);
        var vars = query.split("&");
        for (var i = 0; i < vars.length; i++) {
            var pair = vars[i].split("=");
            if (pair[0] === variable) {
                return pair[1];
            }
        }
        //alert('Query Variable ' + variable + ' not found');
        return undefined;
    };  // var getQueryVariable = function (variable) {
    
    var _setup_h1 = function (_h1, _a) {
        if (_h1.find(".title_link_sep").length === 0) {
            _h1.html(_a);
        }
        else {
            var _h1_html_array = _h1.html().trim().split("\n");
            _h1_html_array.pop();
            _h1.html(_h1_html_array.join("\n")).append(_a);
        }
    };
        
    // --------------------------

    var _backview = getQueryVariable("backview");
    var _backview_title = getQueryVariable("backview_title");
    var _backview_hash = getQueryVariable("backview_hash");
    //console.log(_backview);
    //alert(_backview);

    if (_backview !== undefined) {
        var _h1 = $("h1:first");
        //alert(_h1.length);
        var _domainName;
        if (_h1.find(".title_link_sep").length === 0) {
            _domainName = _h1.text().trim().split(" ")[0];
        }
        else {
            _domainName = _h1.text().trim().split("\n")[2].trim().split(" ")[0];
        }

        //alert(_domainName.split(".").length);
        var _a;
        if (_domainName.split(".").length > 1) {
            var _uri = _backview + "?filter=" + _domainName;
            if (_backview_hash !== undefined) {
                _uri = _uri + "#" + _backview_hash;
            }
            
            if (_h1.find(".title_link_sep").length === 0) {
                _a = $('<a href="' + _uri + '">' + _h1.html() + '</a>');
                _h1.html(_a);
                //_setup_h1(_h1, _a);
            }
            else {
                //alert(_uri);
                //console.log(_uri);
                _h1.find("a[href]").attr("href", _uri);
            }
            console.log("backview setup");
        }
        else if (_backview_title !== undefined) {
            if (_backview_hash !== undefined) {
                _backview = _backview + "#" + _backview_hash;
            }
            _a = $('<span><a href="' + _backview + '">' + _backview_title + '</a>  &gt;</span>');
            _h1.prepend(_a);
            console.log("backview setup");
        }
        else {
            if (_backview_hash !== undefined) {
                _backview = _backview + "#" + _backview_hash;
            }
            _a = $('<a href="' + _backview + '">' + _h1.html() + '</a>');
            _setup_h1(_h1, _a);
            console.log("backview setup");
        }
    }
});

