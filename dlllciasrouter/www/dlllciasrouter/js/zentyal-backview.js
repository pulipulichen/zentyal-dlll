$(function () {
    setTimeout(function () {
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
        };

        var _backview = getQueryVariable("backview");
        var _backview_title = getQueryVariable("backview_title");
        var _backview_hash = getQueryVariable("backview_hash");
        //console.log(_backview);
        //alert(_backview);

        if (_backview !== undefined) {
            var _h1 = $("h1:first");
            //alert(_h1.length);
            var _domainName = _h1.text().trim().split(" ")[0];
            //alert(_domainName.split(".").length);
            var _a;
            if (_domainName.split(".").length > 1) {
                var _uri = _backview + "?filter=" + _domainName;
                if (_backview_hash !== undefined) {
                    _uri = _uri + "#" + _backview_hash;
                }
                _a = $('<a href="' + _uri + '">' + _h1.html() + '</a>');
                _h1.html(_a);
            }
            else if (_backview_title !== undefined) {
                if (_backview_hash !== undefined) {
                    _backview = _backview + "#" + _backview_hash;
                }
                _a = $('<span><a href="' + _backview + '">' + _backview_title + '</a>  &gt;</span>');
                _h1.prepend(_a);
            }
            else {
                if (_backview_hash !== undefined) {
                    _backview = _backview + "#" + _backview_hash;
                }
                _a = $('<a href="' + _backview + '">' + _h1.html() + '</a>');
                _h1.html(_a);
            }
        }
    }, 0);
});